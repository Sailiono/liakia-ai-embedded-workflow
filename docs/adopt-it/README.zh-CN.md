# Adopt it — 把 Liakia 接入你的 STM32 项目

[English](README.md) | 中文说明

这条路径面向已经有 STM32 固件项目、并希望把重复手工交付步骤变成 build / flash / test / evidence 闭环的团队。

Liakia 的定位是包住你们现有技术栈。它不要求替换 HAL、FreeRTOS、CubeCLT、ST-LINK、串口工具或已有调试习惯。

## 适合什么项目

- STM32 板卡 bringup；
- 工控采集板；
- 传感器网关；
- 通信转发板；
- 飞控扩展模块；
- 客户现场 bug 复现；
- 远程测试台回归。

## 你需要提供什么

| 输入 | 示例 |
|---|---|
| 固件仓库 | Git checkout 或源码包 |
| 编译命令 | `cmake --build --preset Debug` |
| 烧录方式 | STM32CubeProgrammer CLI over SWD |
| 串口接口 | shell port、debug port、protocol output port |
| 预期命令 | `version`、`status`、`config`、项目自定义命令 |
| 协议输出 | RTCM、二进制帧、ASCII telemetry、类 Modbus 输出等 |
| 硬件风险说明 | 供电、boot mode、reset 行为、需要避免的破坏性命令 |

## 一周试点形态

| Day | 目标 |
|---:|---|
| 1 | 让 build 和 artifact discovery 脚本化。 |
| 2 | 加入 flash / verify / reset transcript 采集。 |
| 3 | 加入 shell smoke tests 和串口证据。 |
| 4 | 加入 protocol gate 和失败 evidence。 |
| 5 | 加入 register probe、evidence manifest 和 handoff review。 |

实际范围取决于板卡可用性、硬件风险、协议复杂度和已有测试覆盖。

## 接入模型

Liakia 使用 adapter-driven 模型：

```text
project adapter
  -> build command
  -> flash command
  -> serial tests
  -> protocol gates
  -> optional register probe
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
