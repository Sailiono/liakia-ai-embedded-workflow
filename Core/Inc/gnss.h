/**
 * @file    gnss.h
 * @author  Clark Cui
 * @brief   UM982 GNSS initialization state machine and survey-in tracking
 * @date    2026-05-09
 */
#ifndef __GNSS_H
#define __GNSS_H

#include "stm32f4xx_hal.h"

#define GNSS_LINE_BUF_SIZE 512
#define GNSS_MAX_RETRIES 3
#define GNSS_CMD_TIMEOUT_MS 2000
#define GNSS_INIT_DELAY_MS 2000
#define GNSS_SURVEY_MIN_TIME_S 60

typedef enum {
    GNSS_STATE_IDLE,
    GNSS_STATE_INIT,
    GNSS_STATE_CONFIGURING,
    GNSS_STATE_SURVEY_IN,
    GNSS_STATE_FIXED_BASE,
    GNSS_STATE_READY,
    GNSS_STATE_ERROR
} GNSS_State_t;

typedef struct {
    GNSS_State_t state;
    uint8_t current_cmd_idx;
    uint8_t retry_count;
    uint32_t last_cmd_tick;
    uint32_t init_tick;
    uint32_t ack_count;
    uint32_t timeout_count;

    /* Survey-in tracking */
    uint32_t survey_start_tick;
    uint32_t survey_elapsed_s;
    float    survey_accuracy;
    uint8_t  survey_valid;
    uint32_t survey_msg_count;
    char     survey_last_msg[128];
} GNSS_Context_t;

// 获取GNSS上下文用于监控
GNSS_Context_t* GNSS_GetContext(void);

void GNSS_Init(void);
void GNSS_Process(void);
void GNSS_ParseChar(uint8_t ch);
GNSS_State_t GNSS_GetState(void);
void GNSS_Restart(void);

#endif /* __GNSS_H */
