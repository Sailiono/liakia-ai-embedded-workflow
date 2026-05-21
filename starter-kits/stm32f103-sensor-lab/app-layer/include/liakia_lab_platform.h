#ifndef LIAKIA_LAB_PLATFORM_H
#define LIAKIA_LAB_PLATFORM_H

#include <stdbool.h>
#include <stdint.h>

typedef enum {
  LIAKIA_OK = 0,
  LIAKIA_ERR = -1,
  LIAKIA_TIMEOUT = -2
} LiakiaStatus;

uint32_t LiakiaPlatform_Millis(void);
void LiakiaPlatform_UartWrite(const char *data, uint16_t len);
void LiakiaPlatform_LedSet(bool on);
void LiakiaPlatform_SystemReset(void);

LiakiaStatus LiakiaPlatform_I2cReadMem(
    uint8_t addr7,
    uint8_t reg,
    uint8_t *data,
    uint16_t len,
    uint32_t timeout_ms);

LiakiaStatus LiakiaPlatform_I2cWriteMem(
    uint8_t addr7,
    uint8_t reg,
    const uint8_t *data,
    uint16_t len,
    uint32_t timeout_ms);

LiakiaStatus LiakiaPlatform_I2cProbe(uint8_t addr7, uint32_t timeout_ms);
LiakiaStatus LiakiaPlatform_I2cBusRecover(void);

LiakiaStatus LiakiaPlatform_ConfigLoad(void *data, uint16_t len);
LiakiaStatus LiakiaPlatform_ConfigSave(const void *data, uint16_t len);

#endif
