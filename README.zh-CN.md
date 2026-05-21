# Liakia

**AI 辅助嵌入式固件交付闭环**

别再让固件修复丢在编译、烧录、串口验证和交接证据之间。

Liakia 面向 STM32 团队，把这些容易断开的手工步骤整理成一条可复现、可审查、可交接的人审闭环。

[English](README.md) | 中文说明

[![Workflow](https://img.shields.io/badge/Workflow-build_flash_test_evidence-80ff72)]()
[![MCU](https://img.shields.io/badge/MCU-STM32-blue)](https://www.st.com)
[![Mode](https://img.shields.io/badge/AI-Human--in--the--loop-54d7ff)]()
[![Evidence](https://img.shields.io/badge/Evidence-real_bench_%2B_remote_HIL-ffb84d)]()

```text
代码修改 -> 编译 -> 烧录 -> 串口/协议验证 -> 诊断 -> 证据包 -> 交接
```

这个仓库有两个核心角色：

- **dpiny-RTK**：真实 STM32F407 + UM982 工程案例，用来证明这套流程能跑在真实硬件和远程测试台上。
- **Starter-F103 Sensor Lab**：低成本动手实验，用 STM32F103C8T6 + BMP280 让读者亲手体验故障复现、证据采集、AI 诊断和回归验证。

**dpiny-RTK 是示范案例，Liakia 才是工作流。**

## Liakia 解决什么问题

嵌入式项目里，代码本身通常不是唯一难点。真正容易失控的是这些环节：

- 改完代码后，编译、烧录、串口验证靠手工操作；
- 故障现象散落在聊天记录、终端截图和个人记忆里；
- 修复后没有稳定的回归验证，下一次很容易再踩同一个坑；
- 远程测试台依赖同事代操作，结果不可复查；
- 交接时只有“应该好了”，缺少能让别人审查的证据。

Liakia 的做法是把这些步骤脚本化、留痕化，并把 AI 放在人审边界内：AI 可以辅助实现、分析日志、整理假设，但关键硬件判断、风险操作和最终验收仍由工程师确认。

## 选择你的路径

| 路径 | 适合你在什么时候看 | 入口 |
|---|---|---|
| **Learn it / 亲手体验** | 想用一块便宜的 F103 小板，亲手跑一次“故障 -> 证据 -> AI 诊断 -> 修复 -> 回归”。 | [docs/learn-it/README.zh-CN.md](docs/learn-it/README.zh-CN.md) |
| **Trust it / 审查证据** | 想判断这是不是只停留在页面展示，还是确实有真实硬件证据。 | [docs/trust-it/README.zh-CN.md](docs/trust-it/README.zh-CN.md) |
| **Adopt it / 接入项目** | 想把同类编译、烧录、测试和证据归档流程接入自己的 STM32 工程。 | [docs/adopt-it/README.zh-CN.md](docs/adopt-it/README.zh-CN.md) |

## 网页入口

| 页面 | 用途 |
|---|---|
| [初学者页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/beginner.zh-CN.html) | 面向想亲手搭 F103 台架、做故障练习的人。 |
| [专业展示页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.zh-CN.html) | 面向工程师、研发负责人和潜在客户，集中展示证据链、远程测试台、故障复盘和接入路径。 |
| [英文首页](https://sailiono.github.io/liakia-ai-embedded-workflow/index.en.html) | 英文读者入口。 |

## 一眼看证据

| 你想确认什么 | 公开入口 |
|---|---|
| 真实本地测试台是否跑通过 | [evidence/realrun-redacted-2026-05-20/](evidence/realrun-redacted-2026-05-20/) |
| 远程硬件在环是否跑通过 | [evidence/remote-hil-redacted-2026-05-20/](evidence/remote-hil-redacted-2026-05-20/) |
| USB CDC reset 后是否仍可恢复 | [case-studies/04-usb-cdc-reset-recovery.md](case-studies/04-usb-cdc-reset-recovery.md) |
| 协议输出是否能被脚本严格校验 | [tools/rtcm_parse.ps1](tools/rtcm_parse.ps1) |
| 是否有只读寄存器快照 | [tools/register_probe.ps1](tools/register_probe.ps1) |
| 能否迁移到其他 STM32 项目 | [workflow-template/](workflow-template/) |

## 主要命令

dpiny-RTK 参考工程的基线脚本：

```powershell
tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM4 -RtcmPort COM6 -UsbPort COM7
```

可复用工作流模板：

```powershell
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage all
```

Starter-F103 Lab：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

## 边界

Liakia 主要压缩的是可重复的固件交付工作：编译修复、烧录验证、串口回归、协议检查、日志分析、证据归档和交接准备。

它不替代原理图审核、安全决策、EMC/ESD、量产测试治具设计，也不替代最终工程验收。涉及供电、隔离、安全、寄存器写入、启动配置和量产风险的判断，必须由工程师复核。

## 仓库地图

| 区域 | 用途 |
|---|---|
| [firmware/dpiny-rtk/](firmware/dpiny-rtk/) | STM32F407 + UM982 RTK 参考工程案例。 |
| [starter-kits/stm32f103-sensor-lab/](starter-kits/stm32f103-sensor-lab/) | 低成本动手实验和故障练习包。 |
| [evidence/](evidence/) | 公开样例、本地真实测试台、远程硬件在环三类证据包。 |
| [case-studies/](case-studies/) | 故障复盘案例。 |
| [workflow-template/](workflow-template/) | 面向其他 STM32 项目的可配置工作流模板。 |
| [ai-agent/](ai-agent/) | 人审闭环下的 AI 操作规则和检查清单。 |
| [docs/](docs/) | Learn、Trust、Adopt、ROI、商业场景和网页文档。 |
