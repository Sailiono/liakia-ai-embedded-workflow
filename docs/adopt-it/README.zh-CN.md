# Adopt it — 把 Liakia 接入你的 STM32 项目

[English](README.md) | 中文说明

这条路径面向已经有 STM32 固件项目的团队。目标不是替换你们现有的 HAL、FreeRTOS、CubeCLT、ST-LINK、串口工具或调试习惯，而是把重复的交付动作包成一条可运行、可失败留痕、可交接的流程。

第一阶段不追求改造整个研发体系，而是先选一个板卡、一条典型链路，把“编译 -> 烧录 -> 串口/协议验证 -> 证据归档”跑通。

## 适合什么项目

- STM32 板卡 bring-up；
- 工控采集板；
- 传感器网关；
- 通信转发板；
- 飞控扩展模块；
- 客户现场问题复现；
- 远程测试台回归验证。

## 你需要提供什么

| 输入 | 示例 |
|---|---|
| 固件仓库 | Git checkout 或源码包 |
| 编译命令 | `cmake --build --preset Debug` |
| 烧录方式 | STM32CubeProgrammer CLI over SWD |
| 串口接口 | Shell 口、调试口、协议输出口 |
| 预期命令 | `version`、`status`、`config`、项目自定义命令 |
| 协议输出 | RTCM、二进制帧、ASCII telemetry、类 Modbus 输出等 |
| 硬件风险说明 | 供电、boot mode、reset 行为、需要避免的破坏性命令 |

## Liakia STM32 Pilot Package

**交付周期：** 通常 3-5 天，聚焦一套 Windows/STM32 测试台、一个板卡和一条交付链路。跨平台改造、新协议 gate、远程网络加固或生产级 CI 需要单独评估。

**输入：**

- 现有固件工程；
- 编译和烧录方式；
- 串口 Shell 或协议接口；
- 目标板和连接说明；
- 硬件风险说明和需要避免的动作。

**输出：**

- `project-adapter.json`；
- 一条可重复执行的基线脚本；
- 1-3 个串口或协议检查项；
- 失败时也会生成的运行清单；
- 交接报告模板；
- AI 诊断提示词模板；
- 人审边界说明。

## 一周试点形态

| Day | 目标 |
|---:|---|
| 1 | 让编译命令和固件产物发现过程脚本化。 |
| 2 | 加入烧录、校验、复位记录。 |
| 3 | 加入 Shell smoke test 和串口证据。 |
| 4 | 加入协议或业务检查，并确认失败时也能留痕。 |
| 5 | 加入只读寄存器快照、运行清单和交接复核。 |

实际范围取决于板卡可用性、硬件风险、协议复杂度和已有测试覆盖。

## 一周试点结束后，你会得到什么

- 一个可重复执行的基线脚本；
- 一个描述编译、烧录、测试、寄存器快照和证据输出路径的 `project-adapter.json`；
- 能真正判定失败的 Shell 和协议检查；
- 失败时也会生成的证据包；
- 交接报告模板；
- AI 诊断提示词模板；
- 一份团队接入建议，明确哪些步骤适合自动化，哪些必须保留人工复核。

## 接入模型

Liakia 使用项目适配文件描述差异，让工作流保持通用，让项目细节保持显式。

```text
project-adapter.json
  -> build command
  -> flash command
  -> serial tests
  -> protocol checks
  -> optional register snapshot
  -> evidence manifest
```

从这里开始：

- [接入你的 STM32 项目](../adapt-your-stm32-project.zh-CN.md)
- [workflow-template](../../workflow-template/)

## 默认不包含什么

- PCB 重设计；
- EMC/ESD 验证；
- 安全认证；
- 量产测试治具；
- 替换现有固件架构；
- 没有人审的最终验收。

## 接入展示页面

- [专业展示页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.zh-CN.html#adopt)

## 接入前先审查

如果你的团队想先看现有证据，阅读：

- [Trust it / 审查证据](../trust-it/README.zh-CN.md)
