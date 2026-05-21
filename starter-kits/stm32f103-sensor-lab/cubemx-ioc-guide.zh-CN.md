# CubeMX / IOC 配置指南

本 Lab 要求用户自己创建 IOC 和生成底层代码。下面是轨道检查点，用来保证后续应用层可以接入。

## MCU

选择：

```text
STM32F103C8Tx
```

## SYS

| 项 | 配置 |
|---|---|
| Debug | Serial Wire |
| Timebase Source | SysTick |

必须启用 Serial Wire，否则后续 SWD 调试和烧录容易被工程配置关掉。

## RCC / Clock

第一版建议先走保守配置：

| 项 | 配置 |
|---|---|
| HSE | Crystal/Ceramic Resonator，如果板上有 8 MHz 晶振 |
| SYSCLK | 72 MHz |
| APB1 | 36 MHz |
| APB2 | 72 MHz |

如果你的板子 HSE 不稳定，可以先使用 HSI，让 Lab 先跑通，再切回 HSE。

## GPIO

| 引脚 | 配置 | 作用 |
|---|---|---|
| PC13 | GPIO_Output | 板载 LED |
| PA9 | USART1_TX | UART Shell |
| PA10 | USART1_RX | UART Shell |
| PB6 | I2C1_SCL | BMP280 |
| PB7 | I2C1_SDA | BMP280 |

## USART1

| 项 | 配置 |
|---|---|
| Mode | Asynchronous |
| Baud Rate | 115200 |
| Word Length | 8 Bits |
| Parity | None |
| Stop Bits | 1 |
| Hardware Flow Control | None |

第一版可以先用中断或轮询接收，后续高级 case 再引入 DMA + IDLE。

## I2C1

| 项 | 配置 |
|---|---|
| Speed Mode | Standard Mode |
| Clock Speed | 100000 Hz |
| Addressing Mode | 7-bit |

第一版不要直接上 400 kHz。100 kHz 更适合排查接线、上拉和 reset recovery 问题。

## Project Manager

建议：

| 项 | 配置 |
|---|---|
| Toolchain / IDE | STM32CubeIDE 或 CMake，按用户熟悉度选择 |
| Generate peripheral initialization as pair of .c/.h files | Enabled |
| Keep User Code sections | Enabled |

应用层接入时，只在 `USER CODE BEGIN/END` 区域调用 Liakia 函数，避免重新生成代码时丢失修改。

## 接入点

在 `main.c` 中：

```c
/* USER CODE BEGIN Includes */
#include "liakia_lab_app.h"
/* USER CODE END Includes */
```

初始化后：

```c
/* USER CODE BEGIN 2 */
LiakiaLab_Init();
/* USER CODE END 2 */
```

主循环：

```c
/* USER CODE BEGIN WHILE */
while (1)
{
  LiakiaLab_Tick();
  /* USER CODE END WHILE */
  /* USER CODE BEGIN 3 */
}
/* USER CODE END 3 */
```

串口接收回调和平台桥接见 [app-layer/README.zh-CN.md](app-layer/README.zh-CN.md)。
