# Liakia Starter-F103 传感器实验

[English](README.md)

这是 Liakia 面向新用户、评估者和潜在客户的真实动手入口。

主仓库里的 dpiny-RTK 工程证明了一件事：Liakia 可以在真实 STM32F407 + RTK 固件上跑通 build / flash / test / diagnose / evidence handoff 闭环。Starter-F103 Lab 的目的不一样。它不是再展示一个已经跑好的项目，而是让用户自己搭一块低成本 F103 台架，自己生成 IOC，自己接入应用层，再导入我们故意写错的 case，亲手体验一次从失败到证据、从 AI 诊断到最小修复、再到回归 PASS 的过程。

如果要直接开始，先读：

[quick-start.zh-CN.md](quick-start.zh-CN.md)

## 为什么要做这个 Lab

只看展示页或证据包，用户会知道“这套流程曾经跑通过”。但这还不够。

真正有说服力的是让用户自己经历一遍：

1. 焊线并连接 ST-LINK、UART、BMP280；
2. 用 STM32CubeMX 创建自己的 F103 工程；
3. 生成 HAL 初始化代码；
4. 把 Liakia 应用层接进去；
5. 烧录一个正常 baseline；
6. 从某个 known-bad case 文件夹导入故障代码；
7. 看到自动化 gate 失败；
8. 生成 evidence package 和 AI 诊断 prompt；
9. 让 AI 基于证据定位问题；
10. 人工确认后做最小修复；
11. 重新运行同一套 gate，得到 PASS。

这条路径的重点不是“点一下按钮看动画”，而是让用户真实操作硬件、真实引入 bug、真实验证 AI 工作流是否能提高排障效率。

## 这个 Lab 的分工边界

Liakia 不替换用户的嵌入式工程。它把工程包进可复现的测试和证据链。

| 层级 | 由谁负责 | 目的 |
|---|---|---|
| 硬件接线 | 用户 | SWD、UART、I2C、传感器供电、共地 |
| IOC / HAL 生成 | 用户 | 真实 CubeMX 工程，而不是预编译固件 |
| 应用层 | Liakia Starter Kit | Shell、BMP280 检查、telemetry、known-bad 导入 |
| 测试 gate | Liakia 工具 | build、flash、shell、sensor、protocol、reset、register probe |
| 诊断 | 用户 + AI | 基于 evidence 推理，避免瞎猜硬件坏 |
| 回归 | 用户 + Liakia 工具 | 用同一套 gate 证明修复有效，并归档结果 |

## 用户会经历什么

第一轮正常应用应该很平淡：

```text
接线 -> 生成 IOC -> 接入应用层 -> 编译 -> 烧录 -> sensor gate PASS
```

第二轮 known-bad 应该可控地失败：

```text
导入 case 文件夹里的故障代码 -> 编译 -> 烧录 -> gate FAIL -> evidence package 生成
```

第三轮修复后要证明闭环：

```text
AI 诊断 -> 人工 review -> 最小修复 -> 同一套 gate PASS -> manifest 归档
```

这就是 Liakia 工作流的缩小版。

## 推荐第一条路径

先走完整 baseline：

[quick-start.zh-CN.md](quick-start.zh-CN.md)

然后导入第一个 case 包：

[known-bad-cases/case-b-bmp280-calibration/README.zh-CN.md](known-bad-cases/case-b-bmp280-calibration/README.zh-CN.md)

注意：不要一开始就看答案文件。先导入故障代码，烧录，观察现象，生成 evidence，再让 AI 基于 evidence 诊断。最后再打开 `ANSWER.zh-CN.md` 核对。

## Known-Bad Case 包

每个 known-bad case 都是一个独立文件夹，不再是单篇说明文。文件夹里包含：

- 故意改错、可导入的代码；
- 练习指南；
- 单独的答案解析。

| Case | 需要导入什么 | 最适合验证什么 |
|---|---|---|
| [Case B：BMP280 数据质量失败](known-bad-cases/case-b-bmp280-calibration/README.zh-CN.md) | 完整替换 `liakia_lab_app.c` | 第一轮真实运行 |
| [Case A：I2C reset recovery 失败](known-bad-cases/case-a-i2c-bus-stuck-reset/README.zh-CN.md) | 替换 port 层文件 | reset-state 推理 |
| [Case C：UART DMA/IDLE stream 失败](known-bad-cases/case-c-uart-dma-idle-race/README.zh-CN.md) | DMA/IDLE 接收片段 | 高阶串口诊断 |
| [Case D：Flash persistence 失败](known-bad-cases/case-d-flash-persistence-alignment/README.zh-CN.md) | 配置持久化片段 | reset 后状态和 raw record 证据 |

## 推荐硬件

| 物料 | 作用 |
|---|---|
| STM32F103C8T6 Blue Pill 类开发板 | 主控板 |
| ST-LINK 兼容调试器 | SWD 烧录和只读寄存器访问 |
| USB-TTL 3.3 V 串口模块 | USART1 Shell 和 telemetry |
| BMP280 模块 | I2C 传感器，覆盖 chip id、raw value 和数据质量检查 |
| 4.7k 上拉电阻 | 如果 BMP280 模块没有自带 I2C 上拉 |
| 杜邦线 | SWD、UART、I2C、GND 共地 |

## 文档入口

| 文件 | 内容 |
|---|---|
| [quick-start.zh-CN.md](quick-start.zh-CN.md) | 从硬件、IOC、应用层、known-bad 到回归 PASS 的完整快速上手 |
| [bom.zh-CN.md](bom.zh-CN.md) | 物料清单和选型说明 |
| [wiring.zh-CN.md](wiring.zh-CN.md) | 焊线和接线说明 |
| [cubemx-ioc-guide.zh-CN.md](cubemx-ioc-guide.zh-CN.md) | IOC 配置检查点 |
| [app-layer/README.zh-CN.md](app-layer/README.zh-CN.md) | 应用层接入契约 |
| [known-bad-cases/README.zh-CN.md](known-bad-cases/README.zh-CN.md) | 可导入故障代码、练习指南和答案解析 |
| [test-gates.zh-CN.md](test-gates.zh-CN.md) | 测试 gate 和 PASS/FAIL 标准 |
| [diagnosis-playbook.zh-CN.md](diagnosis-playbook.zh-CN.md) | AI 诊断输入和输出格式 |
| [evidence-template/README.zh-CN.md](evidence-template/README.zh-CN.md) | 证据包模板和样例 |
| [troubleshooting.zh-CN.md](troubleshooting.zh-CN.md) | 常见硬件、串口、I2C、reset 问题排查 |
| [tools/](tools/) | Starter runner、F103 register probe、诊断 prompt 生成脚本 |

## 完成标准

完成这个 Lab 后，用户应该能拿出：

- 一个正常运行的 F103 + BMP280 baseline；
- 至少一个从 case 文件夹导入的 known-bad 故障代码；
- 一次失败 gate 和对应 evidence package；
- 一个由 evidence 生成的 AI 诊断 prompt；
- 一个经过人工确认的最小修复；
- 一次重新运行后 PASS 的回归记录。

这证明用户不是“看过 Liakia”，而是真的用 Liakia 的工作流排查过一个嵌入式问题。

## 边界

Starter-F103 Lab 不是完整产品固件，也不替代 dpiny-RTK 工程案例。它是训练台架和采用路径。专业证明仍然来自 STM32F407 + RTK 的真实证据包；Starter Lab 负责把这套方法变成可学习、可动手、可复现的体验。
