# Mission 00: Hardware Connection And Power Check

Do not start by writing code. First make the hardware links observable. Many embedded debug failures are caused by power, logic level, BOOT, SWD, UART direction, or I2C pull-up issues.

## Check Order

1. Soldering
2. Power
3. BOOT0 / BOOT1
4. ST-LINK connection
5. UART adapter voltage level
6. BMP280 power and I2C pull-ups

## Wiring

SWD:

```text
ST-LINK 3.3V  -> target 3V3
ST-LINK GND   -> target GND
ST-LINK SWDIO -> PA13
ST-LINK SWCLK -> PA14
ST-LINK NRST  -> NRST
```

UART:

```text
USB-TTL RXD -> PA9  / USART1_TX
USB-TTL TXD -> PA10 / USART1_RX
USB-TTL GND -> GND
```

BMP280:

```text
BMP280 VCC -> 3V3
BMP280 GND -> GND
BMP280 SCL -> PB6 / I2C1_SCL
BMP280 SDA -> PB7 / I2C1_SDA
```

## PASS Criteria

```text
ST-LINK can connect target
target voltage visible
device id readable
BOOT0 is low
USB-TTL appears as a COM port
BMP280 VCC is 3.3V
SDA/SCL idle high
```

## Common Failures

| Symptom | Check first |
|---|---|
| ST-LINK cannot find target | GND, SWDIO/SWCLK swapped, BOOT0, target power, SWD frequency |
| No serial output | TX/RX direction, shared GND, baud rate, 3.3 V logic |
| I2C no ACK | VCC/GND, SDA/SCL swapped, pull-ups, module address |
| Unstable after reset | NRST not connected, BOOT0 floating, unstable power |

## Evidence To Record

```text
board: STM32F103C8T6 Blue Pill compatible
debug_probe: ST-LINK compatible
shell_uart: COMx
sensor: BMP280
i2c_bus: I2C1 PB6/PB7
power: 3.3V
boot0: low
```
