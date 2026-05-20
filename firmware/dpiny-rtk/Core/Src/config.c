/**
 * @file    config.c
 * @author  Clark Cui
 * @brief   Flash-based configuration load/save with CRC32 validation
 * @date    2026-05-09
 */
#include "config.h"
#include <string.h>
#include <stdio.h>

#define VALID_BAUDRATES_SIZE 8
static const uint32_t valid_baudrates[VALID_BAUDRATES_SIZE] = {
    9600, 14400, 19200, 38400, 57600, 115200, 230400, 460800
};

static AppConfig_t g_config;

/**
 * @brief 计算CRC32校验值
 */
static uint32_t CalculateCRC(uint8_t *data, uint32_t len)
{
    uint32_t crc = 0xFFFFFFFF;
    for (uint32_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            if (crc & 1) crc = (crc >> 1) ^ 0xEDB88320;
            else crc >>= 1;
        }
    }
    return ~crc;
}

/**
 * @brief 检查波特率是否有效
 */
static uint8_t IsValidBaudRate(uint32_t baudrate)
{
    for (uint32_t i = 0; i < VALID_BAUDRATES_SIZE; i++) {
        if (valid_baudrates[i] == baudrate) {
            return 1;
        }
    }
    return 0;
}

/**
 * @brief 设置默认配置
 */
void Config_SetDefault(void)
{
    memset(&g_config, 0, sizeof(AppConfig_t));
    g_config.magic = CONFIG_MAGIC;
    g_config.uart1_baud = 115200;  // RS422输出
    g_config.uart4_baud = 115200;  // GNSS输入
    g_config.gnss_mode = 0;         // 0: Survey-in, 1: Fixed

    /* Default RTCM messages for RTK base station */
    g_config.rtcm_msgs[0] = (RtcmMsg_t){1005, 1};  /* Station ECEF coords, 1Hz */
    g_config.rtcm_msgs[1] = (RtcmMsg_t){1074, 1};  /* GPS MSM4, 1Hz */
    g_config.rtcm_msgs[2] = (RtcmMsg_t){1084, 1};  /* GLONASS MSM4, 1Hz */
    g_config.rtcm_msgs[3] = (RtcmMsg_t){1094, 1};  /* Galileo MSM4, 1Hz */
    g_config.rtcm_msgs[4] = (RtcmMsg_t){1124, 1};  /* BDS MSM4, 1Hz */

    printf("[CONFIG] Default configuration set.\r\n");
}

/**
 * @brief 改进：验证配置有效性
 */
static uint8_t IsConfigValid(AppConfig_t *cfg)
{
    if (cfg == NULL) {
        printf("[CONFIG] Config pointer is NULL\r\n");
        return 0;
    }

    /* 验证魔数 */
    if (cfg->magic != CONFIG_MAGIC) {
        printf("[CONFIG] Invalid magic number: 0x%08lx\r\n", cfg->magic);
        return 0;
    }

    /* 验证波特率 */
    if (!IsValidBaudRate(cfg->uart1_baud)) {
        printf("[CONFIG] Invalid UART1 baud rate: %lu\r\n", cfg->uart1_baud);
        return 0;
    }

    if (!IsValidBaudRate(cfg->uart4_baud)) {
        printf("[CONFIG] Invalid UART4 baud rate: %lu\r\n", cfg->uart4_baud);
        return 0;
    }

    /* 验证GNSS模式 */
    if (cfg->gnss_mode > 1) {
        printf("[CONFIG] Invalid GNSS mode: %lu\r\n", cfg->gnss_mode);
        return 0;
    }

    /* 如果是Fixed模式，验证坐标范围 */
    if (cfg->gnss_mode == 1) {
        if (cfg->fixed_lat < -90.0 || cfg->fixed_lat > 90.0) {
            printf("[CONFIG] Invalid latitude: %lf\r\n", cfg->fixed_lat);
            return 0;
        }
        if (cfg->fixed_lon < -180.0 || cfg->fixed_lon > 180.0) {
            printf("[CONFIG] Invalid longitude: %lf\r\n", cfg->fixed_lon);
            return 0;
        }
    }

    return 1;
}

/**
 * @brief 从Flash加载配置
 */
void Config_Load(void)
{
    AppConfig_t temp;
    memcpy(&temp, (void*)CONFIG_FLASH_ADDR, sizeof(AppConfig_t));

    /* 验证魔数 */
    if (temp.magic != CONFIG_MAGIC) {
        printf("[CONFIG] No valid config found in Flash (magic mismatch).\r\n");
        Config_SetDefault();
        return;
    }

    /* 验证CRC */
    uint32_t crc = CalculateCRC((uint8_t*)&temp, sizeof(AppConfig_t) - 4);
    if (crc != temp.crc) {
        printf("[CONFIG] CRC mismatch, calculated: 0x%08lx, stored: 0x%08lx\r\n", crc, temp.crc);
        Config_SetDefault();
        return;
    }

    /* 验证配置参数有效性 */
    if (!IsConfigValid(&temp)) {
        printf("[CONFIG] Configuration parameters invalid, using defaults.\r\n");
        Config_SetDefault();
        return;
    }

    /* 配置有效，应用配置 */
    memcpy(&g_config, &temp, sizeof(AppConfig_t));
    printf("[CONFIG] Configuration loaded from Flash.\r\n");
    printf("[CONFIG] UART1 baud: %lu, UART4 baud: %lu, GNSS mode: %lu\r\n",
           g_config.uart1_baud, g_config.uart4_baud, g_config.gnss_mode);
}

/**
 * @brief 保存配置到Flash
 */
void Config_Save(void)
{
    /* 在保存前验证配置 */
    if (!IsConfigValid(&g_config)) {
        printf("[CONFIG] Cannot save invalid configuration\r\n");
        return;
    }

    FLASH_EraseInitTypeDef erase_init;
    uint32_t sector_error;

    g_config.crc = CalculateCRC((uint8_t*)&g_config, sizeof(AppConfig_t) - 4);

    HAL_FLASH_Unlock();

    erase_init.TypeErase = FLASH_TYPEERASE_SECTORS;
    erase_init.VoltageRange = FLASH_VOLTAGE_RANGE_3;
    erase_init.Sector = CONFIG_FLASH_SECTOR;
    erase_init.NbSectors = 1;

    if (HAL_FLASHEx_Erase(&erase_init, &sector_error) != HAL_OK) {
        HAL_FLASH_Lock();
        printf("[CONFIG] Flash erase failed! Sector error: %lu\r\n", sector_error);
        return;
    }

    uint32_t *data = (uint32_t*)&g_config;
    for (uint32_t i = 0; i < sizeof(AppConfig_t); i += 4) {
        if (HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, CONFIG_FLASH_ADDR + i, *data++) != HAL_OK) {
            HAL_FLASH_Lock();
            printf("[CONFIG] Flash program failed at offset %lu!\r\n", i);
            return;
        }
    }

    HAL_FLASH_Lock();
    printf("[CONFIG] Configuration saved to Flash (CRC: 0x%08lx).\r\n", g_config.crc);
}

/**
 * @brief 获取配置指针
 */
AppConfig_t* Config_Get(void)
{
    return &g_config;
}
