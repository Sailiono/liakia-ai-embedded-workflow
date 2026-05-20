/**
 * @file    gnss.c
 * @author  Clark Cui
 * @brief   UM982 GNSS non-blocking initialization and survey-in tracking
 * @date    2026-05-09
 */
#include "gnss.h"
#include "config.h"
#include "usart.h"
#include "cmsis_os.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* 改进：使用完整的上下文结构体管理状态 */
static GNSS_Context_t gnss_ctx = {
    .state = GNSS_STATE_IDLE,
    .current_cmd_idx = 0,
    .retry_count = 0,
    .last_cmd_tick = 0,
    .init_tick = 0,
    .ack_count = 0,
    .timeout_count = 0,
    .survey_start_tick = 0,
    .survey_elapsed_s = 0,
    .survey_accuracy = 999.9f,
    .survey_valid = 0,
    .survey_msg_count = 0,
    .survey_last_msg = {0}
};

/* 改进：扩大接收缓冲区避免截断 */
static char gnss_rx_line[GNSS_LINE_BUF_SIZE];
static uint16_t gnss_rx_idx = 0;
static uint8_t command_ack = 0;
static uint8_t survey_report_flag = 0;
static char survey_msg[GNSS_LINE_BUF_SIZE];
static uint8_t no_ack_mode = 0;  /* After mode base, RTCM data floods responses */

/* Dynamic command buffer: built from config at init time */
#define GNSS_CMD_BUF_SIZE 64
#define GNSS_MAX_CMDS 16
static char cmd_buf[GNSS_MAX_CMDS][GNSS_CMD_BUF_SIZE];
static const char *cmd_ptrs[GNSS_MAX_CMDS];
static uint8_t cmd_count = 0;
static uint8_t mode_base_idx = 0;  /* index where no-ack mode starts */

/**
 * @brief Build command list from current AppConfig (constellations + RTCM + save)
 */
static void GNSS_BuildCmdList(void)
{
    AppConfig_t *cfg = Config_Get();
    cmd_count = 0;

    /* Step 1: Enable constellations */
    snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE, "config bds on\r\n");
    snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE, "config gps on\r\n");
    snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE, "config glo on\r\n");
    snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE, "config gal on\r\n");

    /* Step 2: GGA output for monitoring */
    snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE, "log gpgga ontime 5\r\n");

    /* Step 3: Base station mode */
    if (cfg->gnss_mode == 0) {
        snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE, "mode base time 60 1.5 2.0\r\n");
    } else {
        snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE,
                 "mode base fixed %.8f %.8f %.3f\r\n",
                 cfg->fixed_lat, cfg->fixed_lon, cfg->fixed_alt);
    }
    mode_base_idx = cmd_count;  /* RTCM commands start here, use no-ack mode */

    /* Step 4: RTCM messages from config */
    for (int i = 0; i < RTCM_MAX_MSGS && cmd_count < GNSS_MAX_CMDS - 1; i++) {
        if (cfg->rtcm_msgs[i].id == 0) continue;
        snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE,
                 "rtcm%d %d\r\n", cfg->rtcm_msgs[i].id, cfg->rtcm_msgs[i].interval);
    }

    /* Step 5: Save config */
    if (cmd_count < GNSS_MAX_CMDS) {
        snprintf(cmd_buf[cmd_count++], GNSS_CMD_BUF_SIZE, "saveconfig\r\n");
    }

    /* Build pointer array */
    for (uint8_t i = 0; i < cmd_count; i++) {
        cmd_ptrs[i] = cmd_buf[i];
    }
}

/**
 * @brief 解析单个字符，改进缓冲区溢出保护
 */
void GNSS_ParseChar(uint8_t ch)
{
    if (ch == '\r' || ch == '\n')
    {
        if (gnss_rx_idx > 0)
        {
            gnss_rx_line[gnss_rx_idx] = '\0';
            
            if (strstr(gnss_rx_line, "OK") != NULL)
            {
                command_ack = 1;
                gnss_ctx.ack_count++;
            }
            
            if (strstr(gnss_rx_line, "SURVEY") != NULL)
            {
                strncpy(survey_msg, gnss_rx_line, sizeof(survey_msg) - 1);
                survey_msg[sizeof(survey_msg) - 1] = '\0';
                survey_report_flag = 1;

                /* Store latest SURVEY message for shell display */
                strncpy(gnss_ctx.survey_last_msg, gnss_rx_line, sizeof(gnss_ctx.survey_last_msg) - 1);
                gnss_ctx.survey_last_msg[sizeof(gnss_ctx.survey_last_msg) - 1] = '\0';
                gnss_ctx.survey_msg_count++;

                /* Try to parse numeric fields from SURVEY message */
                /* Common formats: "SURVEY <elapsed> <acc>" or "$SURVEY,<elapsed>,<acc>" */
                char *tmp = gnss_rx_line;
                /* Skip non-numeric prefix */
                while (*tmp && (*tmp < '0' || *tmp > '9') && *tmp != '.') tmp++;
                char *num1 = tmp;
                /* Find first number (elapsed seconds or accuracy) */
                char *end1 = NULL;
                float v1 = strtof(num1, &end1);
                if (end1 != num1) {
                    /* Found a number - might be elapsed time */
                    gnss_ctx.survey_elapsed_s = (uint32_t)v1;
                    /* Look for second number (accuracy) */
                    char *num2 = end1;
                    while (*num2 && (*num2 < '0' || *num2 > '9') && *num2 != '.') num2++;
                    char *end2 = NULL;
                    float v2 = strtof(num2, &end2);
                    if (end2 != num2 && v2 > 0.001f && v2 < 999.0f) {
                        gnss_ctx.survey_accuracy = v2;
                        gnss_ctx.survey_valid = 1;
                    }
                }
            }
            
            gnss_rx_idx = 0;
        }
    }
    /* 改进：检查缓冲区大小，防止溢出 */
    else if (gnss_rx_idx < GNSS_LINE_BUF_SIZE - 1)
    {
        gnss_rx_line[gnss_rx_idx++] = ch;
    }
    else
    {
        gnss_rx_idx = 0;
    }
}

/**
 * @brief 初始化GNSS
 */
void GNSS_Init(void)
{
    GNSS_BuildCmdList();
    gnss_ctx.state = GNSS_STATE_INIT;
    gnss_ctx.init_tick = osKernelGetTickCount();
    gnss_ctx.current_cmd_idx = 0;
    gnss_ctx.retry_count = 0;
    printf("[GNSS] Initializing UM982 (%d commands)...\r\n", cmd_count);
}

/**
 * @brief 发送GNSS命令
 */
void GNSS_SendCommand(const char* cmd)
{
    if (cmd == NULL) return;
    HAL_UART_Transmit(&huart4, (uint8_t*)cmd, strlen(cmd), 1000);
}

/**
 * @brief 获取GNSS上下文（用于监控）
 */
GNSS_Context_t* GNSS_GetContext(void)
{
    return &gnss_ctx;
}

/**
 * @brief 获取GNSS状态
 */
GNSS_State_t GNSS_GetState(void)
{
    return gnss_ctx.state;
}

/**
 * @brief 重启GNSS初始化
 */
void GNSS_Restart(void)
{
    GNSS_BuildCmdList();
    gnss_ctx.state = GNSS_STATE_INIT;
    gnss_ctx.init_tick = osKernelGetTickCount();
    gnss_ctx.current_cmd_idx = 0;
    gnss_ctx.retry_count = 0;
    gnss_ctx.ack_count = 0;
    gnss_ctx.timeout_count = 0;
    gnss_ctx.survey_start_tick = 0;
    gnss_ctx.survey_elapsed_s = 0;
    gnss_ctx.survey_accuracy = 999.9f;
    gnss_ctx.survey_valid = 0;
    gnss_ctx.survey_msg_count = 0;
    memset(gnss_ctx.survey_last_msg, 0, sizeof(gnss_ctx.survey_last_msg));
    command_ack = 0;
    no_ack_mode = 0;
    gnss_rx_idx = 0;
    printf("[GNSS] Restarting initialization (%d commands)...\r\n", cmd_count);
}

/**
 * @brief 处理GNSS配置过程 - 改进为非阻塞状态机
 * 
 * 改进说明：
 * 1. 完全非阻塞，不会延迟USB初始化
 * 2. 添加重试机制和错误恢复
 * 3. 状态转换明确，易于调试
 * 4. 支持统计和监控
 */
void GNSS_Process(void)
{
    /* 在线程上下文中报告Survey状态 */
    if (survey_report_flag)
    {
        printf("[GNSS] %s\r\n", survey_msg);
        survey_report_flag = 0;
    }

    switch (gnss_ctx.state)
    {
        case GNSS_STATE_IDLE:
            break;

        case GNSS_STATE_INIT:
            /* 等待初始化延迟 */
            if (osKernelGetTickCount() - gnss_ctx.init_tick >= GNSS_INIT_DELAY_MS)
            {
                gnss_ctx.state = GNSS_STATE_CONFIGURING;
                gnss_ctx.current_cmd_idx = 0;
                gnss_ctx.retry_count = 0;
                /* 置零用于触发首次发送 */
                gnss_ctx.last_cmd_tick = 0;
                printf("[GNSS] Init delay complete, starting configuration\r\n");
            }
            break;

        case GNSS_STATE_CONFIGURING:
            if (gnss_ctx.current_cmd_idx < cmd_count)
            {
                uint32_t now = osKernelGetTickCount();
                uint32_t elapsed = (gnss_ctx.last_cmd_tick == 0) ? 0 : (now - gnss_ctx.last_cmd_tick);

                /* After log gpgga (idx 4), mode base starts. Binary RTCM data will
                   flood the serial line, making OK detection unreliable.
                   Switch to send-and-move-on mode for mode base and beyond. */
                if (gnss_ctx.current_cmd_idx >= mode_base_idx) {
                    no_ack_mode = 1;
                }

                if (no_ack_mode)
                {
                    /* Send each command once, delay briefly, then move on */
                    if (gnss_ctx.last_cmd_tick == 0 || elapsed > 200)
                    {
                        printf("[GNSS] [%d/%d] Sending (no-ack): %s",
                               gnss_ctx.current_cmd_idx + 1,
                               cmd_count,
                               cmd_ptrs[gnss_ctx.current_cmd_idx]);
                        GNSS_SendCommand(cmd_ptrs[gnss_ctx.current_cmd_idx]);
                        command_ack = 0;
                        gnss_ctx.current_cmd_idx++;
                        gnss_ctx.last_cmd_tick = now;
                    }
                }
                /* 首次发送命令 */
                else if (gnss_ctx.last_cmd_tick == 0 || (elapsed > GNSS_CMD_TIMEOUT_MS && !command_ack))
                {
                    if (command_ack || gnss_ctx.last_cmd_tick == 0)
                    {
                        /* 上一个命令成功或这是第一个命令 */
                        command_ack = 0;
                        gnss_ctx.retry_count = 0;

                        printf("[GNSS] [%d/%d] Sending: %s",
                               gnss_ctx.current_cmd_idx + 1,
                               cmd_count,
                               cmd_ptrs[gnss_ctx.current_cmd_idx]);

                        GNSS_SendCommand(cmd_ptrs[gnss_ctx.current_cmd_idx]);
                        gnss_ctx.last_cmd_tick = now;
                    }
                    else if (gnss_ctx.retry_count < GNSS_MAX_RETRIES)
                    {
                        /* 超时重试 */
                        gnss_ctx.retry_count++;
                        gnss_ctx.timeout_count++;

                        printf("[GNSS] [%d/%d] Timeout, retry %d/%d\r\n",
                               gnss_ctx.current_cmd_idx + 1,
                               cmd_count,
                               gnss_ctx.retry_count,
                               GNSS_MAX_RETRIES);

                        GNSS_SendCommand(cmd_ptrs[gnss_ctx.current_cmd_idx]);
                        gnss_ctx.last_cmd_tick = now;
                    }
                    else
                    {
                        /* 超过最大重试次数，跳过此命令 */
                        printf("[GNSS] [%d/%d] Failed after %d retries, skipping\r\n",
                               gnss_ctx.current_cmd_idx + 1,
                               cmd_count,
                               GNSS_MAX_RETRIES);

                        gnss_ctx.current_cmd_idx++;
                        gnss_ctx.retry_count = 0;
                        gnss_ctx.last_cmd_tick = now;
                    }
                }
                else if (command_ack)
                {
                    /* 命令成功 */
                    printf("[GNSS] OK\r\n");
                    command_ack = 0;
                    gnss_ctx.current_cmd_idx++;
                    gnss_ctx.retry_count = 0;
                    gnss_ctx.last_cmd_tick = now;
                }
                /* 否则等待ACK或超时 */
            }
            else
            {
                /* 所有命令发送完成 */
                gnss_ctx.state = GNSS_STATE_SURVEY_IN;
                gnss_ctx.survey_start_tick = osKernelGetTickCount();
                gnss_ctx.survey_elapsed_s = 0;
                gnss_ctx.survey_accuracy = 999.9f;
                gnss_ctx.survey_valid = 0;
                gnss_ctx.survey_msg_count = 0;
                no_ack_mode = 0;
                printf("[GNSS] Configuration complete. Survey-in started.\r\n");
            }
            break;

        case GNSS_STATE_SURVEY_IN:
            /* Update elapsed time from system tick */
            if (gnss_ctx.survey_start_tick > 0) {
                uint32_t new_elapsed = (osKernelGetTickCount() - gnss_ctx.survey_start_tick) / 1000;
                if (new_elapsed > gnss_ctx.survey_elapsed_s && gnss_ctx.survey_msg_count == 0) {
                    gnss_ctx.survey_elapsed_s = new_elapsed;
                }
                /* Auto-transition to READY after minimum survey time */
                if (new_elapsed >= GNSS_SURVEY_MIN_TIME_S
                    && gnss_ctx.state == GNSS_STATE_SURVEY_IN) {
                    gnss_ctx.state = GNSS_STATE_READY;
                    printf("[GNSS] Survey-in minimum time reached, base station ready.\r\n");
                }
            }
            break;

        case GNSS_STATE_ERROR:
            /* 错误状态，可以实现重启逻辑 */
            break;

        default:
            break;
    }
}
