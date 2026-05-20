# Liakia

**AI 原生嵌入式交付闭环示范项目**

[English](README.md) | 中文说明

[![MCU](https://img.shields.io/badge/MCU-STM32F407VET6-blue)](https://www.st.com)
[![GNSS](https://img.shields.io/badge/GNSS-Unicore_UM982-green)](https://www.unicorecomm.com)
[![RTCM](https://img.shields.io/badge/RTCM-3.x_MSM4-orange)](https://www.rtcm.org)
[![Build](https://img.shields.io/badge/Build-CMake_%2B_Ninja-blueviolet)]()
[![Workflow](https://img.shields.io/badge/Workflow-Human--in--the--loop_AI-80ff72)]()

[![AI Embedded Workflow Demo](docs/promo-demo/preview.svg)](https://sailiono.github.io/liakia-ai-embedded-workflow/)

Liakia 是一个公开展示用的 **人审闭环 AI 嵌入式交付工作流** 项目。

它用 **dpiny-RTK** 这个真实的 STM32F407 + UM982 RTK 基准站固件作为第一个硬件案例，但核心价值是固件外侧的交付闭环：

```text
需求 -> 代码修改 -> 编译 -> 烧录 -> 串口测试
-> 协议 gate -> 寄存器 probe -> 证据包 -> 交付
```

**dpiny-RTK 是示范案例，Liakia 才是工作流。**

## 一眼看懂

| 领域 | 本仓库包含什么 |
|---|---|
| 参考固件 | STM32F407 + FreeRTOS 的 UM982 RTK 基准站控制固件 |
| 交付闭环 | CMake 编译、SWD 烧录、串口测试、RTCM CRC gate、USB CDC reset gate、寄存器 probe、证据 manifest |
| 硬件证据 | 已脱敏的本地测试台和远程硬件在环证据包 |
| AI 模型 | AI 辅助实现、日志分析、测试生成和报告草拟；工程师保留最终审核权 |
| 可迁移场景 | STM32 板卡 bringup、固件回归、远程测试台验证、客户现场问题复现 |

## 演示与文档

| 资源 | 链接 |
|---|---|
| 中文交互演示 | [GitHub Pages](https://sailiono.github.io/liakia-ai-embedded-workflow/) |
| 英文交互演示 | [GitHub Pages](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/index.en.html) |
| 证据包入口 | [evidence/README.md](evidence/README.md) |
| 故障复盘案例 | [case-studies/](case-studies/) |
| ROI 模型 | [docs/roi_model.md](docs/roi_model.md) |
| 商业落地场景 | [docs/commercial-use-cases.md](docs/commercial-use-cases.md) |
| 接入你的 STM32 项目 | [docs/adapt-your-stm32-project.zh-CN.md](docs/adapt-your-stm32-project.zh-CN.md) |
| 远程硬件在环流程 | [docs/remote-hardware-debug-flow.md](docs/remote-hardware-debug-flow.md) |
| AI 操作手册 | [ai-agent/](ai-agent/) |
| 可复用工作流模板 | [workflow-template/](workflow-template/) |

## 为什么做这个

嵌入式固件交付经常依赖本地 IDE 编译、手动烧录、人工串口检查、分散的调试记录，以及难以复盘的 bringup 经验。

这个仓库展示的是：如何把这些步骤变成可复现、可审计、可交接的工作流：

- 从命令行编译固件；
- 通过 SWD 烧录并校验目标板；
- 自动测试串口 Shell 行为；
- 用 CRC gate 验证 RTCM 输出；
- 验证 USB CDC reset recovery；
- 采集只读寄存器级证据；
- 生成交付证据包；
- 让 AI 操作保持在明确的人审边界内。

这不是让 AI 盲目替代嵌入式工程师。目标模型是：

```text
AI 加速实现、日志分析、测试生成和文档整理。
工程师负责硬件假设、安全边界、代码 review 和最终验收。
```

## 参考固件

固件源码位于：

```text
firmware/dpiny-rtk/
```

仓库根目录仍保留 CMake 构建入口：

```powershell
cmake --preset Debug
cmake --build --preset Debug
```

主要固件元素：

| 子系统 | 说明 |
|---|---|
| MCU | STM32F407VET6, Cortex-M4F |
| RTOS | FreeRTOS 任务模型 |
| GNSS / RTK | UM982 集成与 RTCM 输出配置 |
| 接口 | USB CDC Shell、USART 调试 Shell、双路 RS422 RTCM 输出 |
| 可靠性 | Watchdog 策略和 Flash 配置持久化 |
| 验证 | Shell 测试、RTCM 解析器、USB CDC reset recovery、寄存器 probe |

这个固件不是合成出来的玩具项目，而是一个真实嵌入式案例。它包含足够的硬件交互，可以覆盖编译、烧录、串口、协议、USB 和寄存器级诊断。

## 工作流入口

主 baseline runner：

```powershell
tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM4 -RtcmPort COM6 -UsbPort COM7
```

它可以执行依赖检查、Debug 固件编译、SWD 烧录与校验、Shell 回归、输入校验、RTCM 解析、USB CDC reset recovery、只读寄存器 probe，以及 evidence manifest 生成。

组件级 runner：

```powershell
tools/functional_test.ps1 -BuildPreset Debug -ComPort COM4
tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10 -OutputJson evidence-out/rtcm_summary.json
tools/usb_cdc_reset_test.ps1 -UsbPort COM7
tools/register_probe.ps1 -Target rcc,gpio,usart,usb,fault -OutputJson evidence-out/register_probe_summary.json
```

可复用工作流模板：

```powershell
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage all
```

如果省略 `-UsbPort`，baseline manifest 会记录 `SKIP_NO_USB_PORT`，而不是悄悄隐藏 USB CDC reset gate。

## 证据包

仓库包含已脱敏的证据包，方便读者在没有原始测试台硬件的情况下查看交付闭环。

| 证据包 | 类型 | 目的 | 结果 |
|---|---|---|---|
| [public-showcase-baseline-2026-05-18](evidence/public-showcase-baseline-2026-05-18/) | 公开展示样例 | 展示 evidence 格式和可公开的寄存器 decode 示例 | PASS |
| [realrun-redacted-2026-05-20](evidence/realrun-redacted-2026-05-20/) | 本地测试台运行 | 展示已移除敏感测试台信息的真实硬件 baseline | PASS |
| [remote-hil-redacted-2026-05-20](evidence/remote-hil-redacted-2026-05-20/) | 远程硬件在环运行 | 展示远程编译、烧录、串口 gate、RTCM CRC、USB CDC reset recovery 和证据回收 | PASS |

典型证据内容：

```text
00_manifest.json
01_environment_check.log
02_build_debug.log
03_flash_verify.log
04_shell_test.log
05_rtcm_parse.log
06_register_probe.log
firmware_sha256.txt
test_summary.md
handoff_report.md
```

公开仓库中的证据已经脱敏。客户交付时应在目标硬件上重新生成原始测试台日志、串口 transcript、STM32CubeProgrammer 输出、寄存器 dump、artifact hash 和时间戳。

## 故障复盘案例

| 案例 | 证据等级 | 展示重点 |
|---|---|---|
| [USART clock missing](case-studies/01-usart-clock-missing.md) | 中高，公开复盘 | 寄存器证据如何把 clock enable 问题和接线、波特率猜测区分开 |
| [RS422 DE timing](case-studies/02-rs422-de-timing.md) | 诊断模式 | RS422 DE 时序应作为传输层故障模式被验证 |
| [RTCM CRC validation](case-studies/03-rtcm-crc-validation.md) | 验证模式 | 协议 gate 应在无帧、CRC 错误或消息类型缺失时失败 |
| [USB CDC reset recovery](case-studies/04-usb-cdc-reset-recovery.md) | 高，真实测试台复盘 | 一次 reset 相关 USB CDC 故障如何变成可重复 regression gate |

Case 04 是目前最强的公开案例，因为它绑定了真实测试台复盘，并且 baseline runner 已经纳入 USB CDC recovery gate。

## 远程硬件在环

远程 HIL 流程让目标板、ST-LINK、USB CDC 口、UART Shell 和 RTCM 适配器保持连接在测试台电脑上。开发者远程触发编译、烧录、串口测试、协议 gate 和证据回收。

```text
开发工作站
  -> 远程测试台命令
  -> 在测试台电脑上编译
  -> 通过本地 ST-LINK 烧录目标板
  -> 运行本地串口和 RTCM gates
  -> 拉回证据包
```

公开仓库只保留脱敏后的主机信息。

## 可复用工作流模板

[workflow-template/](workflow-template/) 中的模板展示了如何让另一个 STM32 项目通过 adapter 描述编译、烧录、测试、寄存器 probe 和 evidence 输出。

这个模板刻意保持保守：

- 不强制切换 IDE；
- 不要求更换固件框架；
- 测试以子进程运行，因此 gate 失败后仍能生成 evidence；
- 拆分 build、flash、test、probe、evidence 阶段；
- 把 summary 写入适合交付审查的 manifest。

## AI 操作边界

[ai-agent/](ai-agent/) 中的 AI 操作手册定义了：

- AI 可以做什么；
- AI 不能做什么；
- 何时必须人工 review；
- flash 前和 commit 前 checklist；
- failure triage report 模板；
- 如何保持修复最小化且基于证据。

这很重要，因为嵌入式项目一旦越过错误边界，可能损坏硬件或引入安全风险。

## ROI 边界

本案例中的公开 ROI 粗略估算如下：

| 路径 | 估算 |
|---|---:|
| AI 辅助交付 | 约 3 人天 + 约 10 元 API 消耗 |
| 保守纯人工估算 | 约 15-25 人天 |
| 粗略周期压缩 | 在本项目条件下约 80%+ |

这些数字的前提是：已有硬件平台、已有 STM32/HAL 基础、目标集中在固件 bringup、自动化验证和证据归档。不包含 PCB 重新设计、EMC 认证、环境测试、安全认证或量产测试治具开发。

这不代表所有嵌入式项目都能达到相同比例。

## 仓库结构

```text
firmware/dpiny-rtk/       参考 STM32 固件案例
tools/                    baseline runner、串口测试、RTCM 解析器、寄存器 probe
workflow-template/        adapter 驱动的可复用工作流模板
evidence/                 公开展示、本地测试台、远程 HIL 证据包
case-studies/             故障复盘与诊断案例
ai-agent/                 AI 操作约束、checklist 和模板
docs/promo-demo/          中英文交互式展示页
docs/                     ROI、商业场景、视频脚本、远程 HIL 文档
```

## 范围与限制

这个仓库不是：

- 生产验收记录；
- 认证包；
- EMC、ESD、安全或环境试验报告；
- 工程 review 的替代品；
- 所有嵌入式项目都能达到同等压缩比例的承诺。

它是一个基于真实固件案例和脱敏测试台证据的嵌入式交付闭环公开展示。

## 版权

Copyright (c) 2026 **Clark Cui**. All rights reserved.
