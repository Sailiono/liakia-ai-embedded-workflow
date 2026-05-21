# 接线说明

## SWD 烧录接线

| ST-LINK | STM32F103C8T6 |
|---|---|
| 3.3V | 3V3 |
| GND | GND |
| SWDIO | PA13 / SWDIO |
| SWCLK | PA14 / SWCLK |
| NRST | NRST，可选但推荐 |

注意：

- 必须共地；
- 不要用 ST-LINK 的 5V 直接给 3.3V 目标引脚供电；
- 如果连接不稳定，优先接上 NRST，并在 STM32CubeProgrammer 中降低 SWD 频率。

## UART Shell 接线

默认使用 USART1：

| USB-TTL | STM32F103C8T6 |
|---|---|
| RXD | PA9 / USART1_TX |
| TXD | PA10 / USART1_RX |
| GND | GND |

默认串口参数：

```text
115200 baud
8 data bits
no parity
1 stop bit
no flow control
```

## BMP280 I2C 接线

默认使用 I2C1：

| BMP280 | STM32F103C8T6 |
|---|---|
| VCC | 3V3 |
| GND | GND |
| SCL | PB6 / I2C1_SCL |
| SDA | PB7 / I2C1_SDA |

如果模块没有自带上拉电阻：

```text
SCL -> 4.7k -> 3V3
SDA -> 4.7k -> 3V3
```

## LED

Blue Pill 常见板载 LED 在 `PC13`，且通常为低电平点亮。不同板卡可能相反，Lab 中会把 LED 作为辅助状态，不作为核心测试项。
