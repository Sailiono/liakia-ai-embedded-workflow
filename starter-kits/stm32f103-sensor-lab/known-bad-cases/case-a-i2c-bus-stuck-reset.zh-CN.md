# Case A：Reset-Related I2C Failure

## 练习卡片

这是第二阶段 case。建议先确认 BMP280 基础路径已经能跑通。

应用层关注位置：

```text
platform I2C recovery path
reset recovery gate
register_probe_f103.ps1
```

练习步骤：

1. 从冷启动后 `sensor id` PASS 的固件开始；
2. 加入或保留一个不完整的 I2C reset-recovery 路径；
3. 编译并烧录；
4. 对比冷启动和 software reset 后的行为；
5. 收集串口日志和寄存器快照。

观察：

```text
diag i2c before reset
sensor id before reset
diag i2c after reset
sensor id after reset
SDA/SCL idle state if available
```

交给 AI 的 evidence：

```text
reset 前后串口日志
RCC_CSR
GPIOB_IDR
I2C1_CR1
I2C1_SR1
I2C1_SR2
platform I2C recovery code
```

## 练习到这里先停止

下面是答案解析。

## 答案解析

典型现象：

```text
power cycle -> sensor id PASS
software reset -> sensor id FAIL
diag i2c -> no ACK
SDA may be low or I2C BUSY may remain set
```

常见根因方向：

- reset 后没有做 I2C bus recovery；
- GPIO 模式切换让 SDA/SCL 状态异常；
- I2C 外设 BUSY 标志残留；
- 从设备停在未完成 transaction 状态。

修复方向：

```text
disable I2C peripheral
temporarily configure SCL/SDA as open-drain GPIO
toggle SCL up to 9 cycles
generate stop-like condition
restore AF open-drain
re-enable I2C peripheral
retry sensor probe
```

回归标准：

```text
power cycle sensor id PASS
software reset sensor id PASS
diag i2c found BMP280
reset recovery PASS
```
