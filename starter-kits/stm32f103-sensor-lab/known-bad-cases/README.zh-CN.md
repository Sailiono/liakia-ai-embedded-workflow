# Known-Bad 故障设计

本 Lab 的 known-bad 不是“地址写错”这类过于简单的问题，而是选择工程中常见、排查成本高、但能通过证据链缩短定位路径的问题。

## Case A：I2C Bus Stuck After Software Reset

现象：

```text
冷启动后 BMP280 偶尔 PASS
software reset 后 sensor gate FAIL
重新断电上电又可能恢复
```

可能根因：

- reset 后 I2C 外设状态未完全恢复；
- SDA 被从设备或 MCU 配置拉低；
- 应用层缺少 I2C bus recovery；
- 初始化顺序中 GPIO open-drain / pull-up 状态不稳定。

证据：

```text
I2C scan result: no ACK
GPIOB_IDR: SDA low
RCC_CSR: software reset flag set
sensor reset recovery gate: FAIL
```

价值：

这类问题通常会被误判为传感器坏、线松、地址错。Liakia 要展示的是：通过 reset reason、GPIO 状态、I2C scan 和恢复动作，把问题从猜测变成证据链。

## Case B：BMP280 Calibration Sign Extension Bug

现象：

```text
chip id PASS
I2C read PASS
raw adc value looks normal
temperature output out of physical range
```

可能根因：

- BMP280 校准参数 signed / unsigned 类型处理错误；
- little-endian 拼接错误；
- 补偿算法中间变量宽度不够；
- 浮点/整数转换边界错误。

证据：

```text
raw calibration bytes: readable
raw adc temperature: in expected range
compensated temperature: invalid
data quality gate: FAIL
```

价值：

它能证明“总线能通”不等于“数据可信”。这比单纯读 chip id 更接近真实产品调试。

## Case C：UART DMA + IDLE Frame Race

现象：

```text
shell command PASS
低频 telemetry PASS
高频 telemetry 偶发 CRC BAD
```

可能根因：

- USART IDLE 标志清除顺序错误；
- DMA NDTR 快照时机错误；
- ring buffer 写指针更新顺序错误；
- 帧尾最后 1 byte 偶发丢失。

证据：

```text
raw frame length occasionally shorter by 1 byte
CRC BAD clustered at frame tail
USART SR / DMA CNDTR snapshot inconsistent
```

价值：

这是工程师真实会遇到的“偶现问题”。Liakia 的优势是把偶现变成统计证据和可重复 gate。

## Case D：Flash Config Persistence Alignment Bug

现象：

```text
config set 后立即读取 PASS
software reset 后配置丢失或字段错位
```

可能根因：

- F103 Flash half-word 写入粒度处理错误；
- page erase 边界错误；
- struct padding 未固定；
- CRC 覆盖范围不一致；
- version 字段升级策略不明确。

证据：

```text
pre-reset config readback: PASS
post-reset config readback: FAIL
flash raw dump: field offset mismatch
persistence gate: FAIL
```

价值：

这类 bug 靠人工随手测试很容易漏掉，适合作为“自动化回归”的核心展示点。

## 第一版建议实现顺序

| 优先级 | Case | 原因 |
|---|---|---|
| P0 | [Case B](case-b-bmp280-calibration.zh-CN.md) | 只依赖 BMP280 和应用层，最容易跨用户环境复现 |
| P1 | [Case D](case-d-flash-persistence-alignment.zh-CN.md) | 能展示 reset recovery 和 evidence 的价值 |
| P2 | [Case A](case-a-i2c-bus-stuck-reset.zh-CN.md) | 需要更强硬件状态采集，展示效果好但实现要谨慎 |
| P3 | [Case C](case-c-uart-dma-idle-race.zh-CN.md) | 专业度最高，但需要 DMA/IDLE 路径，适合第二阶段 |
