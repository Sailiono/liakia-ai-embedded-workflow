# Mission 01: Generate CubeMX / IOC From An Empty Project

This mission asks the user to create the STM32CubeMX project. Liakia does not ship a complete low-level project because real customer projects always have their own IOC, clock tree, pin map, and build habits.

## Minimal Goal

Generate an empty HAL project that builds, flashes, and keeps SWD debug access available.

## Required Configuration

| Module | Setting |
|---|---|
| MCU | STM32F103C8Tx |
| SYS | Debug = Serial Wire |
| RCC | HSE 8 MHz or HSI; prioritize stability for the first pass |
| USART1 | PA9/PA10, 115200 8N1 |
| I2C1 | PB6/PB7, 100 kHz |
| GPIO | PC13 output for onboard LED |

## Do Not Enable In The First Pass

| Feature | Reason |
|---|---|
| FreeRTOS | First verify bare-loop peripherals and evidence chain |
| UART DMA | Introduce later in Case D |
| I2C 400 kHz | Makes wiring and pull-up issues harder to isolate |
| USB CDC | Blue Pill USB hardware varies; keep the first path lower-friction |

## After Code Generation

Confirm these files exist:

```text
Core/Inc/main.h
Core/Src/main.c
Core/Src/gpio.c
Core/Src/usart.c
Core/Src/i2c.c
```

Confirm `main.c` initializes peripherals in a familiar order:

```c
HAL_Init();
SystemClock_Config();
MX_GPIO_Init();
MX_USART1_UART_Init();
MX_I2C1_Init();
```

## PASS Criteria

```text
empty generated project build PASS
ST-LINK flash PASS
debug remains available after flashing
```

## Failure Handling

If flashing fails after generation, check:

- Serial Wire was not disabled;
- BOOT0 is low;
- PA13/PA14 were not reconfigured as ordinary GPIO;
- ST-LINK frequency is not too high.
