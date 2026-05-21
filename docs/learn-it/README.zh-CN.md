# Learn it — Starter-F103 Sensor Lab

[English](README.md) | 中文说明

这条路径面向想**亲手感受 Liakia 工作流**的人，而不是只看别人项目里的证据包。

你会用一块低成本 STM32F103C8T6 板、BMP280 传感器、ST-LINK 和 USB-UART 搭一个小台架。目标不是跑一个永远 PASS 的假 demo，而是先建立正常 baseline，再导入故意写错的应用层代码，采集 evidence，对比人工排查和 AI 辅助排查，最后修复并回归。

## 你会体验什么

```text
焊线
-> 生成 CubeMX IOC
-> 接入 Liakia 应用层
-> 编译和烧录
-> 跑通 baseline
-> 导入 known-bad case
-> 采集失败 evidence
-> 先人工排查
-> 再让 AI 用同一 evidence 分析
-> 修复并回归 PASS
```

## 硬件

| 物料 | 用途 |
|---|---|
| STM32F103C8T6 开发板 | 目标 MCU，常见 Blue Pill 兼容板即可。 |
| ST-LINK | SWD 烧录和调试连接。 |
| USB-UART 适配器 | Shell 和 evidence 采集。 |
| BMP280 模块 | I2C 传感器，用于构造真实感更强的 known-bad case。 |
| 杜邦线 | SWD、UART、I2C、电源和 GND 连接。 |
| 上拉电阻 | 当 BMP280 模块自带上拉不可靠时，用于 I2C。 |

## 四级故障练习

这些 case 不是为了平均难度，而是为了逐步展示 AI 辅助 evidence 分析的价值。

| 推荐顺序 | Case | 训练重点 |
|---:|---|---|
| 1 | Case B — BMP280 数据质量 | I2C 和 chip ID 都能通过，但解码后的传感器数据不可信。 |
| 2 | Case A — I2C reset recovery | reset 后总线可能进入异常状态，需要结合状态和恢复逻辑推理。 |
| 3 | Case D — Flash 持久化 | 配置能保存，但 reset 后不能正确恢复。 |
| 4 | Case C — UART DMA/IDLE stream | stream 边界和时序问题带来更难的诊断。 |

每个 case 文件夹都有 broken app-layer 文件、练习指南和独立答案。完成自己的排查前不要打开答案文件。

## 这里应该怎样使用 AI

把 AI 当成诊断搭档，不要当成直接给答案的黑箱。

1. 运行失败 case，生成 evidence。
2. 先自己排查 15-30 分钟。
3. 记录失败现象、已排除原因、初步假设和耗时。
4. 生成 `ai_prompt.md`。
5. 要求 AI 只能基于日志、gate result、raw value 和 manifest 推理。
6. 对比你的路径和 AI 的路径。
7. 对比完成后再打开答案。

## 开始

完整快速上手：

- [Starter-F103 快速上手](../../starter-kits/stm32f103-sensor-lab/quick-start.zh-CN.md)

然后进入 case 索引：

- [Known-bad 实验包](../../starter-kits/stm32f103-sensor-lab/known-bad-cases/README.zh-CN.md)

初学者网页：

- [初学者页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/beginner.zh-CN.html)

## 下一步看什么

完成一个 case 后，建议继续看：

- [AI 诊断 playbook](../../starter-kits/stm32f103-sensor-lab/diagnosis-playbook.zh-CN.md)
- [测试 gate 定义](../../starter-kits/stm32f103-sensor-lab/test-gates.zh-CN.md)
- [证据包模板](../../starter-kits/stm32f103-sensor-lab/evidence-template/README.zh-CN.md)

如果你想审查更强的工程证据，继续看：

- [Trust it / 审查证据](../trust-it/README.zh-CN.md)
