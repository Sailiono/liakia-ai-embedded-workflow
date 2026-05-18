/**
 * @file    iwdg.h
 * @author  Clark Cui
 * @brief   Independent watchdog with multi-client heartbeat monitoring
 * @date    2026-05-09
 */
#ifndef __IWDG_H
#define __IWDG_H

#ifdef __cplusplus
extern "C" {
#endif

#include "main.h"
#include <stdint.h>

extern IWDG_HandleTypeDef hiwdg;

/* CubeMX-generated init */
void MX_IWDG_Init(void);

typedef enum {
	IWDG_CLIENT_DEFAULT = 0,
	IWDG_CLIENT_GNSS,
	IWDG_CLIENT_PASSTHROUGH,
	IWDG_CLIENT_COUNT
} IWDG_ClientID_t;

void IWDG_Init(void);
void IWDG_Feed(void);
void IWDG_Notify(IWDG_ClientID_t client_id);
void IWDG_Manager_CheckAndFeed(void);
void IWDG_GetStatus(uint32_t *last_feed_tick_out);
uint8_t IWDG_IsInitialized(void);

#ifdef __cplusplus
}
#endif

#endif /* __IWDG_H */
