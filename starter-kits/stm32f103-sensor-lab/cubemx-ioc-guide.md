# CubeMX / IOC Guide

This lab intentionally asks the user to create the IOC and generate the low-level HAL project. These checkpoints keep that generated project compatible with the Liakia application layer.

## MCU

Select:

```text
STM32F103C8Tx
```

## SYS

| Item | Setting |
|---|---|
| Debug | Serial Wire |
| Timebase Source | SysTick |

Serial Wire must remain enabled. Otherwise later SWD flashing and register probing can be disabled by the project configuration itself.

## RCC / Clock

Recommended conservative first pass:

| Item | Setting |
|---|---|
| HSE | Crystal/Ceramic Resonator if the board has a stable 8 MHz crystal |
| SYSCLK | 72 MHz |
| APB1 | 36 MHz |
| APB2 | 72 MHz |

If HSE is unstable on your board, start with HSI, close the lab loop, then return to HSE.

## GPIO

| Pin | Setting | Purpose |
|---|---|---|
| PC13 | GPIO_Output | Onboard LED |
| PA9 | USART1_TX | UART shell |
| PA10 | USART1_RX | UART shell |
| PB6 | I2C1_SCL | BMP280 |
| PB7 | I2C1_SDA | BMP280 |

## USART1

| Item | Setting |
|---|---|
| Mode | Asynchronous |
| Baud Rate | 115200 |
| Word Length | 8 Bits |
| Parity | None |
| Stop Bits | 1 |
| Hardware Flow Control | None |

Use interrupt or polling receive for the first pass. DMA + IDLE belongs to the later Case C path.

## I2C1

| Item | Setting |
|---|---|
| Speed Mode | Standard Mode |
| Clock Speed | 100000 Hz |
| Addressing Mode | 7-bit |

Do not start at 400 kHz. A 100 kHz bus is easier for wiring, pull-up, and reset-recovery diagnosis.

## Project Manager

Recommended:

| Item | Setting |
|---|---|
| Toolchain / IDE | STM32CubeIDE or CMake, whichever you can operate reliably |
| Generate peripheral initialization as pair of .c/.h files | Enabled |
| Keep User Code sections | Enabled |

Place Liakia calls only inside `USER CODE BEGIN/END` sections so CubeMX regeneration does not delete them.

## Integration Points

In `main.c`:

```c
/* USER CODE BEGIN Includes */
#include "liakia_lab_app.h"
/* USER CODE END Includes */
```

After peripheral initialization:

```c
/* USER CODE BEGIN 2 */
LiakiaLab_Init();
/* USER CODE END 2 */
```

Main loop:

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

UART receive callback and HAL bridge details are in [app-layer/README.md](app-layer/README.md).
