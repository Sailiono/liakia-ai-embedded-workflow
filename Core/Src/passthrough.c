/**
 * @file    passthrough.c
 * @author  Clark Cui
 * @brief   DMA-based RTCM passthrough from GNSS (UART4) to RS422 (USART1/USART2)
 * @date    2026-05-09
 */
#include "passthrough.h"
#include "gnss.h"
#include "usart.h"
#include "main.h"
#include "cmsis_os.h"
#include "iwdg.h"
#include <string.h>
#include <stdio.h>

#define UART4_RX_BUF_SIZE 2048
static uint8_t UART4_RxBuf[UART4_RX_BUF_SIZE];
static uint16_t Last_Pos = 0;

/* Ring Buffer for Passthrough - 改进：加倍缓冲区大小 */
#define PASSTHROUGH_BUF_SIZE 8192
static uint8_t Passthrough_Buf[PASSTHROUGH_BUF_SIZE];
static volatile uint16_t Buf_Head = 0;
static volatile uint16_t Buf_Tail = 0;

/* 改进：添加缓冲区监控统计 */
static Passthrough_Stats_t pt_stats = {0};

/* Persistent TX Buffer for DMA */
static uint8_t Passthrough_TxBuf[1024];
osSemaphoreId_t TxSemaphoreHandle;

static volatile uint32_t usart1_error_code = 0;
static volatile uint8_t  usart1_error_flag = 0;

osThreadId_t PassthroughTaskHandle;
const osThreadAttr_t PassthroughTask_attributes = {
  .name = "Passthrough",
  .stack_size = 512 * 4,
  .priority = (osPriority_t) osPriorityRealtime,
};

void PassthroughTask(void *argument);

/**
 * @brief 获取缓冲区可用空间
 */
static inline uint16_t GetBufferFreeSpace(void)
{
    return (Buf_Tail - Buf_Head - 1 + PASSTHROUGH_BUF_SIZE) % PASSTHROUGH_BUF_SIZE;
}

/**
 * @brief 获取缓冲区已用空间
 */
static inline uint16_t GetBufferUsedSpace(void)
{
    return (Buf_Head - Buf_Tail + PASSTHROUGH_BUF_SIZE) % PASSTHROUGH_BUF_SIZE;
}

/**
 * @brief 获取Passthrough统计数据
 */
Passthrough_Stats_t* Passthrough_GetStats(void)
{
    return &pt_stats;
}

void Passthrough_Init(void)
{
    /* Initialize DE pins */
    HAL_GPIO_WritePin(RS422_DE1_GPIO_Port, RS422_DE1_Pin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(RS422_DE2_GPIO_Port, RS422_DE2_Pin, GPIO_PIN_RESET);

    /* Create Semaphore for DMA Sync */
    TxSemaphoreHandle = osSemaphoreNew(1, 1, NULL);

    /* Start UART4 Reception with Idle Interrupt */
    HAL_UARTEx_ReceiveToIdle_DMA(&huart4, UART4_RxBuf, UART4_RX_BUF_SIZE);
    __HAL_DMA_DISABLE_IT(huart4.hdmarx, DMA_IT_HT);

    /* Init USART2 for RTCM mirror output */
    RCC->APB1ENR |= RCC_APB1ENR_USART2EN;
    USART2->BRR = 0x0000016C;
    USART2->CR1 = USART_CR1_TE | USART_CR1_UE;

    /* Create Passthrough Task */
    PassthroughTaskHandle = osThreadNew(PassthroughTask, NULL, &PassthroughTask_attributes);

    printf("[PASSTHROUGH] Initialized, buffer size: %d bytes\r\n", PASSTHROUGH_BUF_SIZE);
}

/**
 * @brief UART4 RX事件回调 - 改进缓冲区溢出检测
 * 
 * 改进说明：
 * 1. 添加缓冲区满检测，避免无声数据丢失
 * 2. 统计丢弃的帧数
 * 3. 记录缓冲区峰值使用率
 * 4. 允许GNSS解析继续进行（单字符解析）
 */
void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t Size)
{
    if (huart->Instance == UART4)
    {
        uint16_t len = 0;
        uint16_t pos = Last_Pos;
        uint16_t dropped = 0;

        if (Size > pos)
        {
            len = Size - pos;
        }
        else if (Size < pos)
        {
            /* Wrap around */
            len = UART4_RX_BUF_SIZE - pos + Size;
        }
        
        /* 处理接收到的数据 */
        uint16_t current_pos = pos;
        for (uint16_t i = 0; i < len; i++)
        {
            uint8_t ch = UART4_RxBuf[current_pos];
            
            /* 检查缓冲区是否有空间 */
            uint16_t free_space = GetBufferFreeSpace();
            
            if (free_space > 0)
            {
                /* 缓冲区有空间，添加数据 */
                Passthrough_Buf[Buf_Head] = ch;
                Buf_Head = (Buf_Head + 1) % PASSTHROUGH_BUF_SIZE;
                pt_stats.rx_bytes++;
                
                /* 更新峰值 */
                uint16_t used = GetBufferUsedSpace();
                if (used > pt_stats.buffer_peak)
                {
                    pt_stats.buffer_peak = used;
                }
            }
            else
            {
                /* 缓冲区满，丢弃数据 */
                dropped++;
                pt_stats.dropped_frames++;
            }
            
            current_pos = (current_pos + 1) % UART4_RX_BUF_SIZE;
        }
        
        /* 警告缓冲区问题 */
        if (dropped > 0)
        {
            pt_stats.overflow_events++;
        }
        
        Last_Pos = Size;
        
        /* Notify task */
        if (PassthroughTaskHandle != NULL)
        {
            osThreadFlagsSet(PassthroughTaskHandle, 0x01);
        }
    }
}

/**
 * @brief Passthrough任务 - 改进错误处理
 */
void PassthroughTask(void *argument)
{
    uint16_t tx_len = 0;
    uint32_t tx_error_count = 0;
    uint32_t last_overflow_events = 0;
    uint32_t last_dropped_frames = 0;

    for (;;)
    {
        /* Heartbeat even when idle, so watchdog won't reset on no-traffic. */
        osThreadFlagsWait(0x01, osFlagsWaitAny, 50);

        /* Report overflow in thread context (ISR内禁止printf). */
        if (pt_stats.overflow_events != last_overflow_events)
        {
            uint32_t delta_overflow = pt_stats.overflow_events - last_overflow_events;
            uint32_t delta_dropped = pt_stats.dropped_frames - last_dropped_frames;
            last_overflow_events = pt_stats.overflow_events;
            last_dropped_frames = pt_stats.dropped_frames;
            printf("[WARNING] Passthrough buffer overflow: +%lu events, +%lu bytes dropped\r\n",
                   delta_overflow, delta_dropped);
        }

        /* Report USART1 errors in thread context */
        if (usart1_error_flag)
        {
            usart1_error_flag = 0;
            printf("[ERROR] USART1 error occurred: %lu\r\n", usart1_error_code);
        }

        while (Buf_Tail != Buf_Head)
        {
            /* Notify watchdog: passthrough task is alive */
            IWDG_Notify(IWDG_CLIENT_PASSTHROUGH);

            /* Ensure DMA is ready */
            if (osSemaphoreAcquire(TxSemaphoreHandle, osWaitForever) != osOK)
            {
                printf("[ERROR] Failed to acquire TX semaphore\r\n");
                osDelay(1);
                continue;
            }

            /* Collect data from ring buffer */
            tx_len = 0;
            while (Buf_Tail != Buf_Head && tx_len < sizeof(Passthrough_TxBuf))
            {
                uint8_t ch = Passthrough_Buf[Buf_Tail];
                Passthrough_TxBuf[tx_len++] = ch;
                Buf_Tail = (Buf_Tail + 1) % PASSTHROUGH_BUF_SIZE;

                /**
                 * NOTE: GNSS parsing is intentionally performed here in the task context
                 * instead of the UART RX ISR. This prevents heavy libc operations 
                 * (strstr, strncpy) from blocking high-priority interrupts.
                 */
                GNSS_ParseChar(ch);
            }

            if (tx_len > 0)
            {
                /* Enable both RS422 DE pins before any TX */
                HAL_GPIO_WritePin(RS422_DE1_GPIO_Port, RS422_DE1_Pin, GPIO_PIN_SET);
                HAL_GPIO_WritePin(RS422_DE2_GPIO_Port, RS422_DE2_Pin, GPIO_PIN_SET);

                /* Mirror RTCM to USART2 (DE2 now HIGH) */
                HAL_UART_Transmit(&huart2, Passthrough_TxBuf, tx_len, 50);

                if (HAL_UART_Transmit_DMA(&huart1, Passthrough_TxBuf, tx_len) == HAL_OK)
                {
                    pt_stats.tx_bytes += tx_len;
                    tx_error_count = 0;
                }
                else
                {
                    /* Handle DMA error */
                    tx_error_count++;

                    if (tx_error_count >= 3)
                    {
                        printf("[ERROR] USART1 DMA failed %lu times, resetting\r\n", tx_error_count);
                        HAL_GPIO_WritePin(RS422_DE1_GPIO_Port, RS422_DE1_Pin, GPIO_PIN_RESET);
                        HAL_GPIO_WritePin(RS422_DE2_GPIO_Port, RS422_DE2_Pin, GPIO_PIN_RESET);
                        osSemaphoreRelease(TxSemaphoreHandle);
                        osDelay(10);
                        tx_error_count = 0;
                    }
                    else
                    {
                        HAL_GPIO_WritePin(RS422_DE1_GPIO_Port, RS422_DE1_Pin, GPIO_PIN_RESET);
                        HAL_GPIO_WritePin(RS422_DE2_GPIO_Port, RS422_DE2_Pin, GPIO_PIN_RESET);
                        osSemaphoreRelease(TxSemaphoreHandle);
                        osDelay(1);
                    }
                }
            }
            else
            {
                osSemaphoreRelease(TxSemaphoreHandle);
            }
        }

        /* No data also counts as alive */
        IWDG_Notify(IWDG_CLIENT_PASSTHROUGH);
    }
}

/**
 * @brief USART1 TX完成回调
 */
void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance == USART1)
    {
        /* Disable both RS422 DE pins */
        HAL_GPIO_WritePin(RS422_DE1_GPIO_Port, RS422_DE1_Pin, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RS422_DE2_GPIO_Port, RS422_DE2_Pin, GPIO_PIN_RESET);
        /* Signal Task that DMA is finished */
        osSemaphoreRelease(TxSemaphoreHandle);
        /* Trigger task to check for more data */
        if (PassthroughTaskHandle != NULL)
        {
            osThreadFlagsSet(PassthroughTaskHandle, 0x01);
        }
    }
}

/**
 * @brief USART1 TX错误回调
 */
void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance == USART1)
    {
        usart1_error_code = huart->ErrorCode;
        usart1_error_flag = 1;
        HAL_GPIO_WritePin(RS422_DE1_GPIO_Port, RS422_DE1_Pin, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RS422_DE2_GPIO_Port, RS422_DE2_Pin, GPIO_PIN_RESET);
        osSemaphoreRelease(TxSemaphoreHandle);
    }
}
