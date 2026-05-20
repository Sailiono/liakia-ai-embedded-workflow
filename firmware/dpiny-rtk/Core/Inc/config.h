/**
 * @file    config.h
 * @author  Clark Cui
 * @brief   Flash-based configuration persistence with CRC32 validation
 * @date    2026-05-09
 */
#ifndef __CONFIG_H
#define __CONFIG_H

#include "stm32f4xx_hal.h"

#define RTCM_MAX_MSGS 8

typedef struct {
    uint16_t id;       /* RTCM message ID, 0 = unused slot */
    uint16_t interval; /* seconds: 0=off, 1=1Hz, 2=0.5Hz, 5=0.2Hz, 10=0.1Hz */
} RtcmMsg_t;

typedef struct {
    uint32_t magic;
    uint32_t uart1_baud;
    uint32_t uart4_baud;
    uint32_t gnss_mode; // 0: Survey-in, 1: Fixed
    double fixed_lat;
    double fixed_lon;
    double fixed_alt;
    RtcmMsg_t rtcm_msgs[RTCM_MAX_MSGS];
    uint32_t crc;
} AppConfig_t;

#define CONFIG_MAGIC 0x44504E59 // "DPNY"
#define CONFIG_FLASH_ADDR 0x08060000 // Sector 7
#define CONFIG_FLASH_SECTOR FLASH_SECTOR_7

void Config_Load(void);
void Config_Save(void);
AppConfig_t* Config_Get(void);

#endif /* __CONFIG_H */
