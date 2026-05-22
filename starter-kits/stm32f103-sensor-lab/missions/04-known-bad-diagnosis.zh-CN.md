# Mission 04：故障练习诊断

这个任务是 Starter Lab 的核心。用户导入一个故意改错的应用层 case，烧录后观察自动检查失败，再用证据定位问题。

## 原则

故障代码以 case 文件夹提供。CubeMX IOC、HAL 初始化、接线、编译、烧录仍然由用户自己完成。

这样能证明：

```text
底层工程由用户自己生成
故障代码是用户主动导入的
自动化检查能拦住失败
AI 分析基于日志、协议帧和寄存器证据
修复动作保持最小、可复核
```

## 第一推荐 case

使用 Case A 文件夹：

```text
known-bad-cases/case-a-bmp280-calibration/
```

先按练习指南操作：

[Case A 练习指南](../known-bad-cases/case-a-bmp280-calibration/README.zh-CN.md)

在生成失败证据包并尝试 AI 诊断之前，不要打开答案文件。

## 采集证据

至少记录：

```text
version output
diag i2c output
sensor id output
sensor read output
telemetry once output
raw calibration or raw protocol bytes
gate result
```

如果有寄存器快照，记录：

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

不要只把一句现象扔给 AI。应该提供：

```text
硬件：STM32F103C8T6 + BMP280
接口：I2C1 PB6/PB7 100 kHz
导入的 case 文件夹：known-bad-cases/case-a-bmp280-calibration
日志：贴 diag i2c / sensor id / sensor read / telemetry once 输出
代码：只贴导入的 app-layer 文件或可疑函数
约束：优先基于证据推理，不要在日志不支持时怀疑硬件
```

完成这一步后，再去读 case 的答案解析。
