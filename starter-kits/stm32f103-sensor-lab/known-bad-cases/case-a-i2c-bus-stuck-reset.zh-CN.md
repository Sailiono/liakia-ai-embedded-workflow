# Case A：I2C Bus Stuck After Software Reset

## 1. 为什么这个 case 有价值

这个问题不是“地址错”或“线没接”这种初级错误。它的特点是：

```text
冷启动可能正常
软件 reset 后失败
断电重上电可能恢复
```

这种现象很容易被误判为传感器质量、接线松动、模块兼容性或随机偶发。它适合展示 Liakia 的优势：把 reset reason、GPIO 状态、I2C scan 和恢复动作串成证据链。

## 2. 预期现象

```text
power cycle -> sensor id PASS
software reset -> sensor id FAIL
diag i2c -> no ACK
SDA idle state -> low
```

## 3. 应收集证据

串口：

```text
version
diag i2c
sensor id
reset
version
diag i2c
sensor id
```

寄存器：

```text
RCC_CSR      reset reason
RCC_APB1ENR  I2C1EN
GPIOB_CRL    PB6/PB7 mode
GPIOB_IDR    SDA/SCL input state
I2C1_CR1     peripheral enable / reset bit
I2C1_SR1     busy / error flags
I2C1_SR2     bus busy state
```

物理：

```text
SDA idle voltage
SCL idle voltage
I2C pull-up presence
whether power-cycle clears the issue
```

## 4. AI 诊断期望

AI 不应该直接下结论“传感器坏了”。合理推理路径是：

```text
chip id 曾经 PASS -> 传感器和地址不是首要嫌疑
software reset 后 FAIL -> reset recovery 路径可疑
SDA low / BUSY set -> I2C 总线可能卡住
power-cycle clears -> 不是永久接线错误
```

更合理的根因假设：

- reset 后未执行 I2C bus recovery；
- GPIO 模式切换导致 SDA/SCL 状态异常；
- I2C 外设 BUSY 标志残留；
- 从设备处于未完成 transaction 状态。

## 5. 修复方向

应用层或 platform 层应实现：

```text
disable I2C peripheral
temporarily configure SCL/SDA as open-drain GPIO
toggle SCL up to 9 cycles
generate stop-like condition
restore AF open-drain
re-enable I2C peripheral
retry sensor probe
```

修复后 gate：

```text
power cycle sensor id PASS
software reset sensor id PASS
diag i2c found BMP280
reset recovery PASS
```

## 6. 不应做的事

- 不应直接把 I2C 频率降到很低后宣称修复；
- 不应把 BMP280 地址硬编码改来改去；
- 不应跳过 reset recovery gate；
- 不应在没有 SDA/SCL 证据时断言模块损坏。
