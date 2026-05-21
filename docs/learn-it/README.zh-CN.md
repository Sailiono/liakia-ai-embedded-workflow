# Learn it — Starter-F103 Sensor Lab

[English](README.md) | 中文说明

这条路径面向想亲手体验 Liakia 的读者。你不是只看一个已经整理好的成功案例，而是自己搭一块低成本小台架，导入故意写错的应用层代码，再用证据驱动的方式把问题找出来。

你会用到：

- STM32F103C8T6 开发板；
- BMP280 I2C 传感器；
- ST-LINK；
- USB-UART；
- 一套可以生成日志、运行清单和 AI 诊断提示词的脚本。

## 你会亲手完成什么

```text
接线
-> 生成 CubeMX IOC
-> 接入 Liakia 应用层
-> 编译和烧录
-> 跑通正常基线
-> 导入故障练习代码
-> 看到自动检查失败
-> 生成证据包
-> 先人工排查
-> 再让 AI 基于同一份证据分析
-> 做最小修复
-> 重新运行并回归 PASS
```

完成第一个故障练习后，你会更清楚地理解：Liakia 不是“让 AI 直接猜答案”，而是先把失败现场整理成证据，再让 AI 帮工程师缩小排查范围。

## 硬件

| 物料 | 用途 |
|---|---|
| STM32F103C8T6 开发板 | 目标 MCU，常见 Blue Pill 兼容板即可。 |
| ST-LINK | SWD 烧录和调试连接。 |
| USB-UART 适配器 | 串口 Shell 和日志采集。 |
| BMP280 模块 | I2C 传感器，用来制造更贴近真实项目的故障。 |
| 杜邦线 | 连接 SWD、UART、I2C、电源和 GND。 |
| 上拉电阻 | 当 BMP280 模块自带上拉不可靠时，用于 I2C。 |

## 四级故障练习

这些练习不是为了平均难度，而是让你逐步感受到 AI 辅助排障在不同问题上的价值。

| 推荐顺序 | 练习 | 训练重点 |
|---:|---|---|
| 1 | Case B — BMP280 数据质量异常 | I2C 和 chip ID 都正常，但解码后的传感器数据不可信。 |
| 2 | Case A — I2C reset 后恢复失败 | 复位前正常，复位后总线状态异常，需要结合状态和恢复逻辑推理。 |
| 3 | Case D — Flash 配置持久化失败 | 保存后立即读取正常，但复位后配置不能正确恢复。 |
| 4 | Case C — UART DMA/IDLE 数据流问题 | 串口流边界和中断时序导致偶发丢帧，排查难度更高。 |

每个 case 都是独立文件夹，里面包含可导入的错误应用层代码、练习步骤和答案解析。建议先完成自己的排查，再打开答案。

## 这里应该怎样使用 AI

把 AI 当成诊断搭档，不要当成直接给答案的黑箱。

1. 导入一个故障练习，编译、烧录并运行脚本。
2. 先自己排查 15-30 分钟，记录失败现象和初步假设。
3. 生成 `ai_prompt.md`，把日志、运行清单和关键原始值交给 AI。
4. 明确要求 AI 只基于证据推理，不要猜硬件损坏。
5. 对比人工路径和 AI 路径。
6. 做最小修复，再用同一套脚本回归。
7. 最后打开答案文件，检查自己的判断是否完整。

## 开始

完整快速上手：

- [Starter-F103 快速上手](../../starter-kits/stm32f103-sensor-lab/quick-start.zh-CN.md)

故障练习入口：

- [故障练习包](../../starter-kits/stm32f103-sensor-lab/known-bad-cases/README.zh-CN.md)

初学者网页：

- [初学者页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/beginner.zh-CN.html)

## 接下来读什么

完成一个 case 后，建议继续看：

- [AI 诊断方法](../../starter-kits/stm32f103-sensor-lab/diagnosis-playbook.zh-CN.md)
- [测试关卡定义](../../starter-kits/stm32f103-sensor-lab/test-gates.zh-CN.md)
- [证据包模板](../../starter-kits/stm32f103-sensor-lab/evidence-template/README.zh-CN.md)

如果你想看更完整的真实工程证据，继续读：

- [Trust it / 审查证据](../trust-it/README.zh-CN.md)
