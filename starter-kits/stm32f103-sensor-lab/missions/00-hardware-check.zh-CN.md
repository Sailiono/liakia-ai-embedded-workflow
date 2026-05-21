# Mission 00：硬件连接与上电检查

目标不是马上写代码，而是先把硬件链路变成可验证状态。很多嵌入式调试失败不是代码问题，而是供电、电平、BOOT、SWD、串口方向或 I2C 上拉问题。

## 检查顺序

1. 检查焊接
2. 检查供电
3. 检查 BOOT0 / BOOT1
4. 检查 ST-LINK 连接
5. 检查串口模块电平
6. 检查 BMP280 供电和 I2C 上拉

## 硬件连接

SWD：

```text
ST-LINK 3.3V  -> 目标板 3V3
ST-LINK GND   -> 目标板 GND
ST-LINK SWDIO -> PA13
ST-LINK SWCLK -> PA14
ST-LINK NRST  -> NRST
```

UART：

```text
USB-TTL RXD -> PA9  / USART1_TX
USB-TTL TXD -> PA10 / USART1_RX
USB-TTL GND -> GND
```

BMP280：

```text
BMP280 VCC -> 3V3
BMP280 GND -> GND
BMP280 SCL -> PB6 / I2C1_SCL
BMP280 SDA -> PB7 / I2C1_SDA
```

## 通过标准

```text
ST-LINK can connect target
target voltage visible
device id readable
BOOT0 is low
USB-TTL appears as a COM port
BMP280 VCC is 3.3V
SDA/SCL idle high
```

## 常见失败

| 现象 | 优先检查 |
|---|---|
| ST-LINK 找不到目标 | GND、SWDIO/SWCLK 反接、BOOT0、目标板供电、SWD 频率 |
| 串口无输出 | TX/RX 方向、GND 共地、波特率、电平是否 3.3V |
| I2C 无 ACK | VCC/GND、SDA/SCL 反接、上拉电阻、模块地址 |
| reset 后行为不稳定 | NRST 未接、BOOT0 悬空、供电不稳 |

## 证据记录

建议把以下信息写入后续 evidence：

```text
board: STM32F103C8T6 Blue Pill compatible
debug_probe: ST-LINK compatible
shell_uart: COMx
sensor: BMP280
i2c_bus: I2C1 PB6/PB7
power: 3.3V
boot0: low
```
