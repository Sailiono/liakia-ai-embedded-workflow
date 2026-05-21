# 后续自动化实现计划

本阶段先把内容写完整。后续再补脚本和工程结构。

## P0：run_starter_f103.ps1

目标：

```text
调用用户工程 build
调用 STM32CubeProgrammer flash
打开串口
运行 shell / sensor / telemetry gates
生成 evidence package
```

要求：

- 不绑定固定 CubeMX 工程路径；
- 用户通过参数传入 build command、ELF 路径和 COM 口；
- 测试失败也必须生成 evidence；
- 每个 gate 都有日志和 exit code；
- manifest 明确 PASS / FAIL / SKIP。

## P1：diagnose_starter_f103.ps1

目标：

```text
读取 evidence package
汇总失败 gate
生成 AI prompt
生成 failure_triage.md
```

不直接调用在线 AI，先生成可复制的 prompt，保持工具链简单。

## P2：register_probe_f103.ps1

目标：

```text
通过 STM32CubeProgrammer -r32 读取关键寄存器
decode RCC / GPIO / USART / I2C / FLASH / reset reason
输出 JSON summary
```

关键寄存器：

```text
RCC_APB1ENR
RCC_APB2ENR
GPIOA_CRL
GPIOB_CRL
GPIOB_IDR
USART1_BRR
I2C1_CR1
I2C1_SR1
I2C1_SR2
RCC_CSR
FLASH_SR
```

## P3：known-bad app variants

把以下 case 的应用层文件补齐：

```text
case-a-i2c-bus-stuck-reset
case-b-bmp280-calibration
case-c-uart-dma-idle-race
case-d-flash-persistence-alignment
```

每个 case 都应有：

```text
known-bad source
expected failing gate
minimal fix hint
regression checklist
```

## P4：网页互动模块

网页上新增 Starter Lab 展示模块：

```text
焊线
IOC
接入应用层
烧录 known-bad
观察 FAIL
AI 诊断
修复 PASS
生成 evidence
```

这个模块只展示路线，不假装替用户跑真实硬件。
