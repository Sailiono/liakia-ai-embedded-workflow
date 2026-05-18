/**
 * @file    passthrough.h
 * @author  Clark Cui
 * @brief   DMA-based RTCM passthrough from UART4 to USART1/USART2
 * @date    2026-05-09
 */
#ifndef __PASSTHROUGH_H
#define __PASSTHROUGH_H

#include "stm32f4xx_hal.h"

typedef struct {
    uint32_t rx_bytes;
    uint32_t tx_bytes;
    uint32_t dropped_frames;
    uint32_t buffer_peak;
    uint32_t overflow_events;
} Passthrough_Stats_t;

void Passthrough_Init(void);
Passthrough_Stats_t* Passthrough_GetStats(void);

#endif /* __PASSTHROUGH_H */
