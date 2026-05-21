# Troubleshooting

## ST-LINK 连接失败

优先检查：

- GND 是否共地；
- SWDIO / SWCLK 是否接反；
- BOOT0 是否为低；
- 是否在 IOC 中关闭了 Serial Wire；
- SWD 频率是否过高；
- NRST 是否建议接上。

建议证据：

```text
STM32CubeProgrammer connect transcript
target voltage
device id
connect mode
SWD frequency
```

## 串口乱码

优先检查：

- USB-TTL 是否 3.3V 电平；
- PA9/PA10 是否反接；
- 波特率是否 115200；
- USART1 是否初始化；
- GND 是否共地。

不要先怀疑应用层。

## Shell 无响应但烧录成功

可能原因：

- 没有调用 `LiakiaLab_Init()`；
- 没有调用 `LiakiaLab_Tick()`；
- 未启用 UART RX 中断；
- `HAL_UART_RxCpltCallback` 没有重新启动接收；
- 串口输出函数没有真正调用 `HAL_UART_Transmit`。

## I2C scan 无设备

优先检查：

- BMP280 是否供电 3.3V；
- SCL/SDA 是否反接；
- PB6/PB7 是否配置为 I2C1；
- 模块是否自带上拉；
- I2C 速度是否过高；
- 地址是否 0x76 或 0x77。

## sensor id PASS 但 sensor read FAIL

这通常不是接线问题。优先检查：

- BMP280 power mode；
- forced measurement 后是否等待转换；
- calibration bytes 读取长度；
- decoded values 是否还能和 raw bytes 对上；
- 导入的故障应用层文件是否改变了数据路径；
- data-quality 检查是在 compensation 前还是后失败。

## reset 后失败

优先检查：

- reset reason；
- I2C bus recovery；
- 传感器是否需要重新配置；
- 配置是否从 Flash 重新加载；
- UART 接收是否重新启动。

## evidence 质量不够

如果 AI 给出的建议很散，通常是输入证据不足。至少补齐：

```text
version
diag i2c
sensor id
sensor read
telemetry once
reset 前后对比
关键代码片段
```
