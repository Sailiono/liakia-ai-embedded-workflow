# Mission 04：Known-Bad 诊断

这个任务是 Starter Lab 的核心。用户烧录有问题的应用层，观察自动化 gate 失败，然后用证据链定位问题。

## 原则

known-bad 只放在应用层，不修改用户自己生成的 IOC 和 HAL 底层工程。

这样能证明：

```text
底层工程是用户自己生成的
应用层问题可以被测试 gate 捕获
AI 分析基于日志、协议帧和寄存器证据
修复动作可以保持最小化
```

## 第一版推荐：Case B

使用：

```text
app-layer/known-bad/case_b_bmp280_calibration/
```

预期现象：

```text
sensor id PASS
raw calibration bytes readable
temperature / pressure data-quality gate FAIL
```

这比 I2C 地址写错更适合展示，因为表面上“传感器已经能读”，但数据仍然不可信。

## 采集证据

至少记录：

```text
version output
sensor id output
sensor read output
telemetry once output
raw calibration bytes
raw adc temperature / pressure
compensated temperature / pressure
data quality gate result
```

如果有 register probe，记录：

```text
RCC_APB1ENR
GPIOB_CRL
GPIOB_IDR
I2C1_CR1
I2C1_SR1
I2C1_SR2
USART1_BRR
```

## AI 输入要求

不要只把一句“温度不对”扔给 AI。应该提供：

```text
硬件：STM32F103C8T6 + BMP280
接口：I2C1 PB6/PB7 100 kHz
现象：chip id PASS，但补偿后数据超范围
日志：贴 sensor id / sensor read / telemetry once 输出
代码：贴 calibration 读取和补偿函数
约束：优先查应用层，不怀疑硬件，除非证据支持
```

## 预期定位方向

Case B 的重点不是总线，而是：

- BMP280 校准参数 little-endian 拼接；
- signed / unsigned 类型；
- 中间变量宽度；
- 补偿公式是否和 datasheet 一致；
- raw adc 正常但 compensated value 异常。
