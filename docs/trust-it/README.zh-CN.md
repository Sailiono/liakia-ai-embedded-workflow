# Trust it — 工程证据审查

[English](README.md) | 中文说明

这条路径面向嵌入式工程师、CTO、研发负责人和技术型客户。它的目的不是再解释 Liakia 的概念，而是让你检查：这套流程到底有没有真实硬件证据，失败时能不能留下可复查的材料，AI 的行为边界是否清楚。

这里的证据来自真实 STM32 固件项目和远程硬件在环测试台，公开内容已做脱敏处理。

## 优先审查什么

| 你要确认的问题 | 公开证据 |
|---|---|
| 这套流程是否跑在真实硬件上 | [realrun-redacted-2026-05-20](../../evidence/realrun-redacted-2026-05-20/) |
| 是否能在远程测试台上执行 | [remote-hil-redacted-2026-05-20](../../evidence/remote-hil-redacted-2026-05-20/) |
| 协议检查能不能真正挡住错误输出 | [RTCM parser](../../tools/rtcm_parse.ps1) |
| USB CDC reset 后是否仍可恢复 | [Case 04](../../case-studies/04-usb-cdc-reset-recovery.md) |
| 是否有寄存器级证据 | [register_probe.ps1](../../tools/register_probe.ps1) |
| AI 是否被限制在人审边界内 | [AI agent playbook](../../ai-agent/) |

## 审查顺序

如果你是工程师或研发负责人，建议按下面顺序看：

1. 先看远程硬件在环的 `manifest`，确认每一步都有 `step`、`result` 和耗时。
2. 再看 RTCM CRC 检查，确认 `CRC BAD = 0`，并且脚本有明确退出码，不只是打印日志。
3. 再看 USB CDC reset 案例，确认 reset 前后都有可复查的串口证据。
4. 再看 `register_probe.ps1`，确认它是只读采集，并且能解释关键 bit。
5. 再看 AI 操作规则，确认烧录、寄存器写入、安全相关动作不会绕过人工确认。
6. 最后看工作流模板，判断这套流程如何迁移到另一个 STM32 项目。

## 证据包

| 证据包 | 类型 | 用途 | 结果 |
|---|---|---|---|
| [public-showcase-baseline-2026-05-18](../../evidence/public-showcase-baseline-2026-05-18/) | 公开格式样例 | 展示证据包结构和可公开的寄存器解释示例 | PASS |
| [realrun-redacted-2026-05-20](../../evidence/realrun-redacted-2026-05-20/) | 本地测试台运行 | 脱敏后的真实硬件基线记录 | PASS |
| [remote-hil-redacted-2026-05-20](../../evidence/remote-hil-redacted-2026-05-20/) | 远程硬件在环运行 | 远程编译、烧录、串口检查、RTCM CRC、USB CDC reset 恢复和证据回传 | PASS |

建议优先打开这些文件：

```text
00_manifest.json
02_build_debug.log
03_flash_verify.log
04_shell_test.log
05_rtcm_parse.log
06_register_probe.log
test_summary.md
handoff_report.md
```

## 重点案例

当前最强公开案例是：

- [Case 04 — USB CDC Shell Recovery After Software Reset](../../case-studies/04-usb-cdc-reset-recovery.md)

它展示的关键模式是：问题不是修一次就结束，而是沉淀成下一次必跑的回归验证。以后同类问题再出现，脚本会直接挡住，而不是靠工程师记忆。

## 远程硬件在环

远程硬件在环让目标板、ST-LINK、USB CDC、UART Shell 和 RTCM 采集口保持连接在测试台电脑上。开发者远程触发同一套流程，证据在真正连接硬件的机器上生成，再回传到开发侧。

阅读：

- [远程硬件调试流程](../remote-hardware-debug-flow.md)

## 工程边界

Liakia 是公开展示项目和工作流模板，不是生产验收记录、安全认证、EMC 报告，也不替代工程签字。

客户交付时，应在目标硬件上重新生成原始测试台日志，包括：

- STM32CubeProgrammer 输出；
- 串口 Shell 原始记录；
- 协议解析摘要；
- 寄存器快照；
- 固件产物哈希；
- 时间戳；
- 交接摘要。

## 专业展示页面

- [专业展示页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.zh-CN.html)

## 下一步

如果你想把这套流程接入自己的固件项目，继续读：

- [Adopt it / 接入项目](../adopt-it/README.zh-CN.md)
