#include "stm32f1xx_hal.h"

#include <stdint.h>
#include <string.h>

#define LIAKIA_CASE_C_RX_SIZE 128u

static uint8_t rx_dma_buf[LIAKIA_CASE_C_RX_SIZE];
static uint8_t frame_buf[LIAKIA_CASE_C_RX_SIZE];
static volatile uint16_t frame_len;
static volatile uint8_t frame_ready;

void LiakiaCaseC_Start(UART_HandleTypeDef *huart) {
  frame_len = 0;
  frame_ready = 0;
  HAL_UART_Receive_DMA(huart, rx_dma_buf, sizeof(rx_dma_buf));
  __HAL_UART_ENABLE_IT(huart, UART_IT_IDLE);
}

void LiakiaCaseC_UartIrq(UART_HandleTypeDef *huart, DMA_HandleTypeDef *hdma) {
  if (__HAL_UART_GET_FLAG(huart, UART_FLAG_IDLE) == RESET) {
    return;
  }

  uint16_t len = (uint16_t)(sizeof(rx_dma_buf) - __HAL_DMA_GET_COUNTER(hdma));

  frame_len = len;
  frame_ready = 1;

  __HAL_UART_CLEAR_IDLEFLAG(huart);
  HAL_UART_DMAStop(huart);

  if (len > sizeof(frame_buf)) {
    len = sizeof(frame_buf);
  }

  memcpy(frame_buf, rx_dma_buf, len);
  memset(rx_dma_buf, 0, sizeof(rx_dma_buf));

  HAL_UART_Receive_DMA(huart, rx_dma_buf, sizeof(rx_dma_buf));
}

uint8_t LiakiaCaseC_TryGetFrame(uint8_t *out, uint16_t *len) {
  if (frame_ready == 0u) {
    return 0u;
  }

  if (*len > frame_len) {
    *len = frame_len;
  }

  memcpy(out, frame_buf, *len);
  frame_ready = 0u;
  return 1u;
}
