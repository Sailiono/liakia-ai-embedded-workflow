#include "liakia_lab_platform.h"

#include "gpio.h"
#include "i2c.h"
#include "main.h"
#include "usart.h"

#include <string.h>

uint32_t LiakiaPlatform_Millis(void) {
  return HAL_GetTick();
}

void LiakiaPlatform_UartWrite(const char *data, uint16_t len) {
  (void)HAL_UART_Transmit(&huart1, (uint8_t *)data, len, 200);
}

void LiakiaPlatform_LedSet(bool on) {
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, on ? GPIO_PIN_RESET : GPIO_PIN_SET);
}

void LiakiaPlatform_SystemReset(void) {
  HAL_Delay(50);
  NVIC_SystemReset();
}

LiakiaStatus LiakiaPlatform_I2cReadMem(
    uint8_t addr7,
    uint8_t reg,
    uint8_t *data,
    uint16_t len,
    uint32_t timeout_ms) {
  return HAL_I2C_Mem_Read(&hi2c1, (uint16_t)(addr7 << 1), reg, I2C_MEMADD_SIZE_8BIT, data, len, timeout_ms) == HAL_OK
    ? LIAKIA_OK
    : LIAKIA_ERR;
}

LiakiaStatus LiakiaPlatform_I2cWriteMem(
    uint8_t addr7,
    uint8_t reg,
    const uint8_t *data,
    uint16_t len,
    uint32_t timeout_ms) {
  return HAL_I2C_Mem_Write(&hi2c1, (uint16_t)(addr7 << 1), reg, I2C_MEMADD_SIZE_8BIT, (uint8_t *)data, len, timeout_ms) == HAL_OK
    ? LIAKIA_OK
    : LIAKIA_ERR;
}

LiakiaStatus LiakiaPlatform_I2cProbe(uint8_t addr7, uint32_t timeout_ms) {
  return HAL_I2C_IsDeviceReady(&hi2c1, (uint16_t)(addr7 << 1), 1, timeout_ms) == HAL_OK
    ? LIAKIA_OK
    : LIAKIA_ERR;
}

LiakiaStatus LiakiaPlatform_I2cBusRecover(void) {
  return LIAKIA_ERR;
}

LiakiaStatus LiakiaPlatform_ConfigLoad(void *data, uint16_t len) {
  (void)data;
  (void)len;
  return LIAKIA_ERR;
}

LiakiaStatus LiakiaPlatform_ConfigSave(const void *data, uint16_t len) {
  (void)data;
  (void)len;
  return LIAKIA_ERR;
}
