# Mission 01：从空工程生成 CubeMX / IOC

这个任务要求用户自己创建 STM32CubeMX 工程。Liakia 不提供完整底层工程，原因是：真实迁移时客户项目一定有自己的 IOC、时钟树、外设映射和工程习惯。

## 最小目标

生成一个可以编译、可以烧录、保留 SWD 调试能力的空 HAL 工程。

## 必选配置

| 模块 | 配置 |
|---|---|
| MCU | STM32F103C8Tx |
| SYS | Debug = Serial Wire |
| RCC | HSE 8 MHz 或 HSI，第一版以稳定为先 |
| USART1 | PA9/PA10, 115200 8N1 |
| I2C1 | PB6/PB7, 100 kHz |
| GPIO | PC13 输出，作为板载 LED |

## 不建议第一版开启

| 功能 | 原因 |
|---|---|
| FreeRTOS | 第一版先验证裸循环和外设证据链 |
| DMA UART | 后续 Case D 再引入，否则新手入口复杂度太高 |
| I2C 400 kHz | 接线和上拉问题更容易被放大 |
| USB CDC | F103 Blue Pill 的 USB 硬件差异较多，第一版不要把门槛抬高 |

## 生成代码后检查

确认工程中存在：

```text
Core/Inc/main.h
Core/Src/main.c
Core/Src/gpio.c
Core/Src/usart.c
Core/Src/i2c.c
```

确认 `main.c` 初始化顺序类似：

```c
HAL_Init();
SystemClock_Config();
MX_GPIO_Init();
MX_USART1_UART_Init();
MX_I2C1_Init();
```

## 通过标准

```text
empty generated project build PASS
ST-LINK flash PASS
debug remains available after flashing
```

## 失败处理

如果生成后无法烧录，优先检查：

- 是否误关闭 Serial Wire；
- BOOT0 是否为低；
- 是否配置了会占用 PA13/PA14 的普通 GPIO；
- ST-LINK 连接频率是否过高。
