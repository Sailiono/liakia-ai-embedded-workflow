# Wiring

## SWD Flash Wiring

| ST-LINK | STM32F103C8T6 |
|---|---|
| 3.3V | 3V3 |
| GND | GND |
| SWDIO | PA13 / SWDIO |
| SWCLK | PA14 / SWCLK |
| NRST | NRST, optional but recommended |

Notes:

- The probe and target must share ground.
- Do not feed 5 V into 3.3 V target pins.
- If connection is unstable, connect NRST and lower the SWD frequency in STM32CubeProgrammer.

## UART Shell Wiring

The starter lab uses USART1 by default:

| USB-TTL | STM32F103C8T6 |
|---|---|
| RXD | PA9 / USART1_TX |
| TXD | PA10 / USART1_RX |
| GND | GND |

Default serial settings:

```text
115200 baud
8 data bits
no parity
1 stop bit
no flow control
```

## BMP280 I2C Wiring

The starter lab uses I2C1 by default:

| BMP280 | STM32F103C8T6 |
|---|---|
| VCC | 3V3 |
| GND | GND |
| SCL | PB6 / I2C1_SCL |
| SDA | PB7 / I2C1_SDA |

If the module has no onboard pull-ups:

```text
SCL -> 4.7k -> 3V3
SDA -> 4.7k -> 3V3
```

## LED

Most Blue Pill compatible boards use `PC13` as the onboard LED, often active-low. The lab uses the LED as a simple observable state, not as a core pass/fail signal.
