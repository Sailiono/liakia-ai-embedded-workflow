# Liakia

**AI 辅助嵌入式固件交付闭环**

面向需要可复现 build、flash、test、diagnose、evidence、handoff 的 STM32 团队。

[English](README.md) | 中文说明

[![Workflow](https://img.shields.io/badge/Workflow-build_flash_test_evidence-80ff72)]()
[![MCU](https://img.shields.io/badge/MCU-STM32-blue)](https://www.st.com)
[![Mode](https://img.shields.io/badge/AI-Human--in--the--loop-54d7ff)]()
[![Evidence](https://img.shields.io/badge/Evidence-real_bench_%2B_remote_HIL-ffb84d)]()

嵌入式交付最容易失控的地方，是代码修改、硬件验证和交接证据之间的断点。

Liakia 把这些断点串成一条能在真实或远程 STM32 硬件上复现的人审闭环：

```text
build -> flash -> test -> diagnose -> evidence -> handoff
```

这个仓库用 **dpiny-RTK** 作为工程可信度案例，用 **Starter-F103 Sensor Lab** 作为动手学习路径。

**dpiny-RTK 是示范案例，Liakia 才是工作流。**

## Liakia 是什么

Liakia 不是一个固件库，也不是单一 RTK 产品。它是一套让嵌入式固件工作变得可复现、可审查、可交接的流程：

- 从命令行编译固件；
- 通过 SWD 烧录并校验目标板；
- 自动运行串口、协议、reset 和寄存器级 gates；
- 生成包含日志、manifest、summary 的 evidence package；
- 让 AI 辅助实现和诊断，但最终审核权保留给工程师。

## 选择你的路径

| 路径 | 适合你在什么时候看 | 入口 |
|---|---|---|
| **Learn it / 亲手体验** | 你想用低成本 STM32F103 + BMP280 台架，亲自体验 AI 辅助排障。 | [docs/learn-it/README.zh-CN.md](docs/learn-it/README.zh-CN.md) |
| **Trust it / 审查证据** | 你想看真实 bench、remote HIL、故障复盘和工程边界。 | [docs/trust-it/README.zh-CN.md](docs/trust-it/README.zh-CN.md) |
| **Adopt it / 接入项目** | 你想把 build / flash / test / evidence 闭环接入自己的 STM32 工程。 | [docs/adopt-it/README.zh-CN.md](docs/adopt-it/README.zh-CN.md) |

## 网页入口

| 页面 | 用途 |
|---|---|
| [初学者页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/beginner.zh-CN.html) | 面向想亲手搭 F103 台架的人。 |
| [专业展示页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.zh-CN.html) | 面向工程师、研发负责人和潜在客户，展示证据链、远程 HIL、故障复盘和接入路径。 |
| [英文首页](https://sailiono.github.io/liakia-ai-embedded-workflow/index.en.html) | 英文读者入口。 |

## 一眼看证据

| 证据 | 公开入口 |
|---|---|
| 真实本地测试台证据 | [evidence/realrun-redacted-2026-05-20/](evidence/realrun-redacted-2026-05-20/) |
| 远程硬件在环证据 | [evidence/remote-hil-redacted-2026-05-20/](evidence/remote-hil-redacted-2026-05-20/) |
| USB CDC reset recovery 案例 | [case-studies/04-usb-cdc-reset-recovery.md](case-studies/04-usb-cdc-reset-recovery.md) |
| RTCM CRC gate | [tools/rtcm_parse.ps1](tools/rtcm_parse.ps1) |
| 只读寄存器 probe | [tools/register_probe.ps1](tools/register_probe.ps1) |
| 可复用 adapter 工作流 | [workflow-template/](workflow-template/) |

## 主要命令

参考工程 baseline runner：

```powershell
tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM4 -RtcmPort COM6 -UsbPort COM7
```

可复用工作流模板：

```powershell
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage all
```

Starter-F103 Lab runner：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

## 边界

Liakia 主要压缩可重复的固件交付工作：编译修复、烧录验证、串口回归、协议 gate、日志分析、证据归档和 handoff 准备。

它不替代原理图审核、安全决策、EMC/ESD、量产测试治具设计和最终工程验收。

## 仓库地图

| 区域 | 用途 |
|---|---|
| [firmware/dpiny-rtk/](firmware/dpiny-rtk/) | STM32F407 + UM982 RTK 参考工程案例。 |
| [starter-kits/stm32f103-sensor-lab/](starter-kits/stm32f103-sensor-lab/) | 低成本动手 Lab 和 known-bad 排障 case。 |
| [evidence/](evidence/) | public、real bench、remote HIL 三类证据包。 |
| [case-studies/](case-studies/) | 故障复盘案例。 |
| [workflow-template/](workflow-template/) | 面向其他 STM32 项目的 adapter-driven 工作流模板。 |
| [ai-agent/](ai-agent/) | 人审闭环 AI 操作规则和 checklist。 |
| [docs/](docs/) | Learn、Trust、Adopt、ROI、商业场景和网页文档。 |
