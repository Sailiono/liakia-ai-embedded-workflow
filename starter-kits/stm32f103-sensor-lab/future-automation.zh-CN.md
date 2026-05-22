# 后续自动化增强计划

当前仓库已经提供第一版脚本：

```text
tools/run_starter_f103.ps1
tools/diagnose_starter_f103.ps1
tools/register_probe_f103.ps1
```

后续计划集中在增强真实硬件覆盖、故障练习代码变体和网页交互。

## 已实现：run_starter_f103.ps1

目标：

```text
调用用户工程 build
调用 STM32CubeProgrammer flash
打开串口
运行 shell / sensor / telemetry 检查
生成证据包
```

要求：

- 不绑定固定 CubeMX 工程路径；
- 用户通过参数传入 build command、ELF 路径和 COM 口；
- 测试失败也必须生成证据；
- 每个检查项都有日志和退出码；
- manifest 明确 PASS / FAIL / SKIP。

## 已实现：diagnose_starter_f103.ps1

目标：

```text
读取证据包
汇总失败检查项
生成 AI 诊断提示词
生成 failure_triage.md
```

不直接调用在线 AI，先生成可复制的提示词，保持工具链简单。

## 已实现：register_probe_f103.ps1

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
GPIOA_CRH
GPIOB_CRL
GPIOB_IDR
USART1_BRR
I2C1_CR1
I2C1_SR1
I2C1_SR2
RCC_CSR
FLASH_SR
```

## P1：故障练习代码变体

把以下 case 的应用层文件补齐：

```text
case-a-bmp280-calibration
case-b-i2c-bus-stuck-reset
case-c-flash-persistence-alignment
case-d-uart-dma-idle-race
```

每个 case 都应有：

```text
known-bad source
expected failing gate
minimal fix hint
regression checklist
```

## P2：网页互动模块

网页上新增 Starter Lab 展示模块：

```text
焊线
IOC
接入应用层
烧录故障代码
观察 FAIL
AI 诊断
修复 PASS
生成证据包
```

这个模块只展示路线，不假装替用户跑真实硬件。
