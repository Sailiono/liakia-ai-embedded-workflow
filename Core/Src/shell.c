/**
 * @file    shell.c
 * @author  Clark Cui
 * @brief   Interactive shell with GNSS/passthrough/config commands
 * @date    2026-05-09
 */
#include "shell.h"
#include "config.h"
#include "passthrough.h"
#include "gnss.h"
#include "iwdg.h"
#include "cmsis_os.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define SHELL_BUF_SIZE 128
static char shell_buf[SHELL_BUF_SIZE];
static uint16_t shell_idx = 0;

typedef void (*shell_func_t)(int argc, char **argv);

typedef struct {
    const char *cmd;
    shell_func_t func;
    const char *help;
} shell_cmd_t;

static void cmd_help(int argc, char **argv);
static void cmd_status(int argc, char **argv);
static void cmd_config(int argc, char **argv);
static void cmd_save(int argc, char **argv);
static void cmd_reset(int argc, char **argv);
static void cmd_baud(int argc, char **argv);
static void cmd_usb(int argc, char **argv);
static void cmd_version(int argc, char **argv);
static void cmd_gnss(int argc, char **argv);
static void cmd_rtcm(int argc, char **argv);

static const shell_cmd_t commands[] = {
    {"help",    cmd_help,    "Show this help"},
    {"status",  cmd_status,  "Show system status"},
    {"config",  cmd_config,  "View current configuration"},
    {"gnss",    cmd_gnss,    "GNSS config: gnss [status|restart|mode survey|mode fixed <lat> <lon> <alt>]"},
    {"rtcm",    cmd_rtcm,    "RTCM config: rtcm [list|add <id> <freq>|remove <id>|freq <id> <freq>]"},
    {"save",    cmd_save,    "Save configuration to Flash"},
    {"reset",   cmd_reset,   "Reset system"},
    {"baud",    cmd_baud,    "Set baudrate: baud <uart> <rate> (uart: 1 or 4)"},
    {"usb",     cmd_usb,     "Show USB CDC connection status"},
    {"version", cmd_version, "Show firmware version"},
};

#define CMD_COUNT (sizeof(commands) / sizeof(commands[0]))

void Shell_Init(void) {
    shell_idx = 0;
    printf("\r\n");
    printf("============================================\r\n");
    printf("  dpiny-RTK Base Station v1.0\r\n");
    printf("  Type 'help' for available commands\r\n");
    printf("============================================\r\n");
    printf(">");
}

static void cmd_help(int argc, char **argv) {
    printf("Available commands:\r\n");
    for (int i = 0; i < CMD_COUNT; i++) {
        printf("  %-10s - %s\r\n", commands[i].cmd, commands[i].help);
    }
}

static const char *GNSS_StateToStr(GNSS_State_t state)
{
    switch (state) {
    case GNSS_STATE_IDLE: return "IDLE";
    case GNSS_STATE_INIT: return "INIT";
    case GNSS_STATE_CONFIGURING: return "CONFIG";
    case GNSS_STATE_SURVEY_IN: return "SURVEY";
    case GNSS_STATE_FIXED_BASE: return "FIXED";
    case GNSS_STATE_READY: return "READY";
    case GNSS_STATE_ERROR: return "ERROR";
    default: return "UNKNOWN";
    }
}

static void cmd_status(int argc, char **argv) {
    Passthrough_Stats_t* pt = Passthrough_GetStats();
    GNSS_Context_t* gnss = GNSS_GetContext();
    printf("--- System Status ---\r\n");
    printf("Passthrough:\r\n");
    printf("  RX Bytes: %lu\r\n", pt->rx_bytes);
    printf("  TX Bytes: %lu\r\n", pt->tx_bytes);
    printf("  Dropped:  %lu\r\n", pt->dropped_frames);
    printf("  Peak:     %lu\r\n", pt->buffer_peak);
    printf("  Overflow: %lu\r\n", pt->overflow_events);

    if (gnss != NULL) {
        printf("GNSS:\r\n");
        printf("  State:    %lu (%s)\r\n", (uint32_t)gnss->state, GNSS_StateToStr(gnss->state));
        printf("  CmdIdx:   %lu\r\n", (uint32_t)gnss->current_cmd_idx);
        printf("  Retries:  %lu\r\n", (uint32_t)gnss->retry_count);
        printf("  ACK:      %lu\r\n", gnss->ack_count);
        printf("  Timeout:  %lu\r\n", gnss->timeout_count);
    }

    printf("Watchdog:\r\n");
    if (IWDG_IsInitialized()) {
        uint32_t last_feed_tick = 0;
        IWDG_GetStatus(&last_feed_tick);
        printf("  IWDG:     ON\r\n");
        printf("  FeedAge:  %lu ms\r\n", (uint32_t)(HAL_GetTick() - last_feed_tick));
    } else {
        printf("  IWDG:     OFF\r\n");
    }
}

static void cmd_config(int argc, char **argv) {
    AppConfig_t* cfg = Config_Get();
    printf("--- Configuration ---\r\n");
    printf("  UART1 Baud: %lu\r\n", cfg->uart1_baud);
    printf("  UART4 Baud: %lu\r\n", cfg->uart4_baud);
    printf("  GNSS Mode:  %lu (%s)\r\n", cfg->gnss_mode, cfg->gnss_mode == 0 ? "Survey-in" : "Fixed");
    if (cfg->gnss_mode == 1) {
        printf("  Fixed Lat:  %lf\r\n", cfg->fixed_lat);
        printf("  Fixed Lon:  %lf\r\n", cfg->fixed_lon);
    }
    printf("  RTCM Msgs:\r\n");
    for (int i = 0; i < RTCM_MAX_MSGS; i++) {
        if (cfg->rtcm_msgs[i].id == 0) continue;
        printf("    MT%d @ %ds\r\n", cfg->rtcm_msgs[i].id, cfg->rtcm_msgs[i].interval);
    }
}

static void cmd_save(int argc, char **argv) {
    printf("Saving config to Flash...\r\n");
    Config_Save();
}

static void cmd_reset(int argc, char **argv) {
    printf("Resetting system...\r\n");
    osDelay(100);
    HAL_NVIC_SystemReset();
}

static void cmd_baud(int argc, char **argv) {
    if (argc < 3) {
        printf("Usage: baud <uart_id> <rate>\r\n");
        return;
    }
    int id = atoi(argv[1]);
    uint32_t rate = strtoul(argv[2], NULL, 10);
    AppConfig_t* cfg = Config_Get();
    if (id == 1) cfg->uart1_baud = rate;
    else if (id == 4) cfg->uart4_baud = rate;
    else {
        printf("Invalid UART ID. Use 1 (RS422) or 4 (GNSS).\r\n");
        return;
    }
    printf("UART%d baudrate set to %lu. Call 'save' and 'reset' to apply.\r\n", id, rate);
}

static void cmd_usb(int argc, char **argv) {
    (void)argc;
    (void)argv;
    extern uint8_t CDC_IsConnected(void);
    printf("--- USB CDC Status ---\r\n");
    printf("  Connected: %s\r\n", CDC_IsConnected() ? "YES" : "NO");
}

static void cmd_version(int argc, char **argv) {
    (void)argc;
    (void)argv;
    printf("dpiny-RTK Base Station Firmware\r\n");
    printf("  Version: v1.0\r\n");
    printf("  Build:   " __DATE__ " " __TIME__ "\r\n");
    printf("  MCU:     STM32F407VET6 @ 168MHz\r\n");
    printf("  GNSS:    Unicore UM982\r\n");
    printf("  RTOS:    FreeRTOS (CMSIS-RTOS v2)\r\n");
}

static double simple_atof(const char *str)
{
    double result = 0.0;
    double fraction = 0.0;
    double divisor = 1.0;
    int sign = 1;
    int in_fraction = 0;

    if (*str == '-') { sign = -1; str++; }
    while (*str) {
        if (*str == '.') {
            in_fraction = 1; str++;
            continue;
        }
        if (*str < '0' || *str > '9') break;
        if (in_fraction) {
            divisor *= 10.0;
            fraction = fraction * 10.0 + (double)(*str - '0');
        } else {
            result = result * 10.0 + (double)(*str - '0');
        }
        str++;
    }
    return sign * (result + fraction / divisor);
}

static void cmd_gnss(int argc, char **argv) {
    AppConfig_t* cfg = Config_Get();

    if (argc < 2 || strcmp(argv[1], "status") == 0) {
        GNSS_Context_t* gnss = GNSS_GetContext();
        printf("--- GNSS Status ---\r\n");
        printf("  State:     %s\r\n", GNSS_StateToStr(gnss->state));
        printf("  Mode:      %s\r\n", cfg->gnss_mode == 0 ? "Survey-in" : "Fixed");
        if (cfg->gnss_mode == 1) {
            printf("  Fixed Lat: %.8f\r\n", cfg->fixed_lat);
            printf("  Fixed Lon: %.8f\r\n", cfg->fixed_lon);
            printf("  Fixed Alt: %.3f\r\n", cfg->fixed_alt);
        }
        printf("  ACK:       %lu\r\n", gnss->ack_count);
        printf("  Timeout:   %lu\r\n", gnss->timeout_count);

        /* Survey-in progress details */
        if (gnss->state == GNSS_STATE_SURVEY_IN) {
            uint32_t elapsed = gnss->survey_elapsed_s;
            uint32_t target  = 60;  /* mode base time 60 */
            float    acc_req = 1.5f; /* mode base ... 1.5 (meters) */
            printf("\r\n  --- Survey-in Progress ---\r\n");
            printf("  Elapsed:   %lu s / %lu s min", elapsed, target);
            if (elapsed >= target) {
                printf(" [DONE]");
            } else {
                uint32_t pct = (elapsed * 100) / target;
                if (pct > 100) pct = 100;
                printf(" (%lu%%)", pct);
            }
            printf("\r\n");
            printf("  Accuracy Threshold: %.1f m\r\n", (double)acc_req);
            if (gnss->survey_valid) {
                printf("  Accuracy Estimate:  %.3f m\r\n", (double)gnss->survey_accuracy);
            } else {
                if (elapsed < target) {
                    printf("  Accuracy Estimate:  (waiting for GNSS report)\r\n");
                } else {
                    printf("  Accuracy Estimate:  (checking)\r\n");
                }
            }
            printf("  Survey Reports: %lu\r\n", gnss->survey_msg_count);
            if (gnss->survey_last_msg[0]) {
                printf("  Last Report:  %s\r\n", gnss->survey_last_msg);
            }
        }
        return;
    }

    if (strcmp(argv[1], "restart") == 0) {
        GNSS_Restart();
        printf("GNSS re-initialization started.\r\n");
        return;
    }

    if (strcmp(argv[1], "mode") == 0) {
        if (argc < 3) {
            printf("Usage: gnss mode <survey|fixed> [lat lon alt]\r\n");
            return;
        }
        if (strcmp(argv[2], "survey") == 0) {
            cfg->gnss_mode = 0;
            printf("GNSS mode set to Survey-in. Use 'save' and 'reset' to apply.\r\n");
        } else if (strcmp(argv[2], "fixed") == 0) {
            if (argc < 6) {
                printf("Usage: gnss mode fixed <lat> <lon> <alt>\r\n");
                return;
            }
            cfg->gnss_mode = 1;
            cfg->fixed_lat = simple_atof(argv[3]);
            cfg->fixed_lon = simple_atof(argv[4]);
            cfg->fixed_alt = simple_atof(argv[5]);
            printf("GNSS mode set to Fixed Base:\r\n");
            printf("  Lat: %.8f, Lon: %.8f, Alt: %.3f\r\n",
                   cfg->fixed_lat, cfg->fixed_lon, cfg->fixed_alt);
            printf("Use 'save' and 'reset' to apply.\r\n");
        } else {
            printf("Unknown mode: %s. Use 'survey' or 'fixed'.\r\n", argv[2]);
        }
        return;
    }

    printf("Unknown gnss subcommand: %s\r\n", argv[1]);
    printf("Usage: gnss [status|restart|mode survey|mode fixed <lat> <lon> <alt>]\r\n");
}

static const char *rtcm_msg_desc(uint16_t id) {
    switch (id) {
    case 1005: return "Station ECEF";
    case 1006: return "Station ECEF+Height";
    case 1033: return "Antenna Info";
    case 1074: return "GPS MSM4";
    case 1077: return "GPS MSM7";
    case 1084: return "GLONASS MSM4";
    case 1087: return "GLONASS MSM7";
    case 1094: return "Galileo MSM4";
    case 1097: return "Galileo MSM7";
    case 1124: return "BDS MSM4";
    case 1127: return "BDS MSM7";
    default:   return "";
    }
}

static void cmd_rtcm(int argc, char **argv) {
    AppConfig_t *cfg = Config_Get();

    if (argc < 2 || strcmp(argv[1], "list") == 0) {
        printf("--- RTCM Messages ---\r\n");
        printf("  %-8s %-8s %-6s %s\r\n", "Slot", "MsgID", "Freq", "Description");
        printf("  %-8s %-8s %-6s %s\r\n", "----", "-----", "----", "-----------");
        int count = 0;
        for (int i = 0; i < RTCM_MAX_MSGS; i++) {
            if (cfg->rtcm_msgs[i].id == 0) continue;
            const char *desc = rtcm_msg_desc(cfg->rtcm_msgs[i].id);
            printf("  %-8d %-8d %-6d %s\r\n",
                   i, cfg->rtcm_msgs[i].id, cfg->rtcm_msgs[i].interval, desc);
            count++;
        }
        if (count == 0) printf("  (none)\r\n");
        printf("  %d/%d slots used. Use 'save' and 'reset' to apply changes.\r\n", count, RTCM_MAX_MSGS);
        return;
    }

    if (strcmp(argv[1], "add") == 0) {
        if (argc < 3) {
            printf("Usage: rtcm add <id> [freq]  (freq: 0=off,1=1Hz,2=0.5Hz,5=0.2Hz,10=0.1Hz)\r\n");
            return;
        }
        uint16_t id = (uint16_t)atoi(argv[2]);
        uint16_t freq = (argc >= 4) ? (uint16_t)atoi(argv[3]) : 1;

        /* Find empty slot or same ID */
        int slot = -1;
        for (int i = 0; i < RTCM_MAX_MSGS; i++) {
            if (cfg->rtcm_msgs[i].id == id) { slot = i; break; }
            if (cfg->rtcm_msgs[i].id == 0 && slot < 0) slot = i;
        }
        if (slot < 0) {
            printf("Error: all %d RTCM slots full. Remove one first.\r\n", RTCM_MAX_MSGS);
            return;
        }
        cfg->rtcm_msgs[slot].id = id;
        cfg->rtcm_msgs[slot].interval = freq;
        printf("RTCM %d set to freq=%d (%s). Use 'save' and 'reset' to apply.\r\n",
               id, freq, rtcm_msg_desc(id));
        return;
    }

    if (strcmp(argv[1], "remove") == 0) {
        if (argc < 3) {
            printf("Usage: rtcm remove <id>\r\n");
            return;
        }
        uint16_t id = (uint16_t)atoi(argv[2]);
        for (int i = 0; i < RTCM_MAX_MSGS; i++) {
            if (cfg->rtcm_msgs[i].id == id) {
                cfg->rtcm_msgs[i].id = 0;
                cfg->rtcm_msgs[i].interval = 0;
                printf("RTCM %d removed. Use 'save' and 'reset' to apply.\r\n", id);
                return;
            }
        }
        printf("RTCM %d not found in config.\r\n", id);
        return;
    }

    if (strcmp(argv[1], "freq") == 0) {
        if (argc < 4) {
            printf("Usage: rtcm freq <id> <interval>\r\n");
            printf("  interval: 0=off, 1=1Hz, 2=0.5Hz, 5=0.2Hz, 10=0.1Hz\r\n");
            return;
        }
        uint16_t id = (uint16_t)atoi(argv[2]);
        uint16_t interval = (uint16_t)atoi(argv[3]);
        for (int i = 0; i < RTCM_MAX_MSGS; i++) {
            if (cfg->rtcm_msgs[i].id == id) {
                cfg->rtcm_msgs[i].interval = interval;
                printf("RTCM %d frequency set to %d. Use 'save' and 'reset' to apply.\r\n", id, interval);
                return;
            }
        }
        printf("RTCM %d not found. Use 'rtcm add %d %d' first.\r\n", id, id, interval);
        return;
    }

    printf("Unknown rtcm subcommand: %s\r\n", argv[1]);
    printf("Usage: rtcm [list|add <id> [freq]|remove <id>|freq <id> <freq>]\r\n");
}

static void Shell_Execute(char *line) {
    char *argv[10];
    int argc = 0;
    char *token = strtok(line, " ");
    while (token != NULL && argc < 10) {
        argv[argc++] = token;
        token = strtok(NULL, " ");
    }

    if (argc == 0) return;

    for (int i = 0; i < CMD_COUNT; i++) {
        if (strcmp(argv[0], commands[i].cmd) == 0) {
            commands[i].func(argc, argv);
            return;
        }
    }
    printf("Unknown command: %s\r\n", argv[0]);
}

void Shell_Printf(const char *fmt, ...) {
    char buf[256];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    printf("%s", buf);
}

void Shell_ProcessChar(uint8_t ch) {
    if (ch == '\r' || ch == '\n') {
        if (shell_idx > 0) {
            shell_buf[shell_idx] = '\0';
            printf("\r\n");
            Shell_Execute(shell_buf);
            shell_idx = 0;
            printf("\r\n>");
        } else {
            printf("\r\n>");
        }
    } else if (ch == '\b' || ch == 127) {
        if (shell_idx > 0) {
            shell_idx--;
            printf("\b \b");
        }
    } else if (shell_idx < SHELL_BUF_SIZE - 1) {
        shell_buf[shell_idx++] = ch;
        putchar(ch); // Echo
    }
}
