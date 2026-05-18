/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file    iwdg.c
  * @author  Clark Cui (multi-client heartbeat manager)
  * @brief   This file provides code for the configuration
  *          of the IWDG instances.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "iwdg.h"

/* USER CODE BEGIN 0 */

static uint32_t last_feed_tick = 0;
static uint8_t iwdg_initialized = 0;
static uint32_t client_heartbeats[IWDG_CLIENT_COUNT] = {0};

/* USER CODE END 0 */

IWDG_HandleTypeDef hiwdg;

/* IWDG init function */
void MX_IWDG_Init(void)
{

  /* USER CODE BEGIN IWDG_Init 0 */

  /* USER CODE END IWDG_Init 0 */

  /* USER CODE BEGIN IWDG_Init 1 */

  /* USER CODE END IWDG_Init 1 */
  hiwdg.Instance = IWDG;
  hiwdg.Init.Prescaler = IWDG_PRESCALER_64;
  hiwdg.Init.Reload = 4095;
  if (HAL_IWDG_Init(&hiwdg) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN IWDG_Init 2 */

  iwdg_initialized = 1;
  last_feed_tick = HAL_GetTick();
  
  /* Initialize heartbeats */
  for (int i = 0; i < IWDG_CLIENT_COUNT; i++) {
      client_heartbeats[i] = last_feed_tick;
  }

  /* USER CODE END IWDG_Init 2 */

}

/* USER CODE BEGIN 1 */

void IWDG_Init(void)
{
  if (iwdg_initialized)
  {
    return;
  }

  /* CubeMX 生成的初始化：Prescaler=64, Reload=4095（LSI≈32kHz 时约 8s，受 LSI 误差影响） */
  MX_IWDG_Init();

  iwdg_initialized = 1;
  last_feed_tick = HAL_GetTick();

  /* 刚启动后先喂一次，减少边界风险 */
  HAL_IWDG_Refresh(&hiwdg);
}

void IWDG_Feed(void)
{
  if (!iwdg_initialized)
  {
    return;
  }

  HAL_IWDG_Refresh(&hiwdg);
  last_feed_tick = HAL_GetTick();
}

/**
 * @brief 任务报告存活状态
 */
void IWDG_Notify(IWDG_ClientID_t client_id)
{
    if (client_id < IWDG_CLIENT_COUNT) {
        client_heartbeats[client_id] = HAL_GetTick();
    }
}

/**
 * @brief 看门狗管理器：检查所有任务是否存活，汇总后决定是否喂狗
 * 
 * 策略：如果任一任务超过 5000ms 未汇报，则停止喂狗，触发系统复位。
 */
void IWDG_Manager_CheckAndFeed(void)
{
    if (!iwdg_initialized) return;

    uint32_t current_tick = HAL_GetTick();
    uint8_t all_alive = 1;

    for (int i = 0; i < IWDG_CLIENT_COUNT; i++) {
        /* 处理 Tick 溢出：HAL_GetTick() 返回 uint32_t */
        if (current_tick - client_heartbeats[i] > 5000) {
            all_alive = 0;
            break;
        }
    }

    if (all_alive) {
        IWDG_Feed();
    }
}

void IWDG_GetStatus(uint32_t *last_feed_tick_out)
{
  if (last_feed_tick_out != NULL)
  {
    *last_feed_tick_out = last_feed_tick;
  }
}

uint8_t IWDG_IsInitialized(void)
{
  return iwdg_initialized;
}

/* USER CODE END 1 */
