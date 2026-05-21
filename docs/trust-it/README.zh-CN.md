# Trust it — 工程证据审查

[English](README.md) | 中文说明

这条路径面向嵌入式工程师、CTO、研发负责人和技术型客户，用来判断 Liakia 是否只是叙事，还是确实有工程可信度。

这里的证明不是 PPT，而是来自真实 STM32 固件项目和远程硬件在环测试台的脱敏证据包、故障复盘、脚本和工作流边界。

## 优先审查什么

| 问题 | 公开证据 |
|---|---|
| 这套流程是否跑在真实硬件上？ | [realrun-redacted-2026-05-20](../../evidence/realrun-redacted-2026-05-20/) |
| 是否能通过远程测试台执行？ | [remote-hil-redacted-2026-05-20](../../evidence/remote-hil-redacted-2026-05-20/) |
| 协议 gate 是否能客观失败？ | [RTCM parser](../../tools/rtcm_parse.ps1) |
| USB CDC reset recovery 是否覆盖？ | [Case 04](../../case-studies/04-usb-cdc-reset-recovery.md) |
| 是否有寄存器级证据？ | [register_probe.ps1](../../tools/register_probe.ps1) |
| AI 是否受人审边界约束？ | [AI agent playbook](../../ai-agent/) |

## 审查清单

如果你是嵌入式工程师或研发负责人，建议按这个顺序审查：

1. 先看 remote HIL manifest，确认 step、result、duration 字段是否完整。
2. 再看 RTCM CRC gate，确认 `CRC BAD = 0`，并且它是 gate，不只是日志查看器。
3. 再看 USB CDC reset case，确认 reset 前后都有证据。
4. 再看 `register_probe.ps1`，确认它只读，并且有 bit decode。
5. 再看 AI operation boundary，确认有硬件风险的动作仍然处在人审边界内。
6. 最后看 adapter template，判断这套 loop 如何迁移到另一个 STM32 项目。

## 证据包

| 证据包 | 类型 | 目的 | 结果 |
|---|---|---|---|
| [public-showcase-baseline-2026-05-18](../../evidence/public-showcase-baseline-2026-05-18/) | 公开格式样例 | 展示 evidence 结构和可公开的 decode 示例 | PASS |
| [realrun-redacted-2026-05-20](../../evidence/realrun-redacted-2026-05-20/) | 本地测试台运行 | 脱敏后的真实硬件 baseline | PASS |
| [remote-hil-redacted-2026-05-20](../../evidence/remote-hil-redacted-2026-05-20/) | 远程硬件在环运行 | 远程 build、flash、serial gates、RTCM CRC、USB CDC reset recovery 和 evidence pullback | PASS |

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

它展示的关键工程模式是：问题不是修一次就结束，而是被沉淀成 baseline runner 中的可重复 regression gate。

## 远程硬件在环

远程 HIL 让目标板、ST-LINK、USB CDC、UART Shell 和 RTCM 适配器保持连接在测试台电脑上。开发者远程触发流程，证据在真正连接硬件的机器上生成。

阅读：

- [远程硬件调试流程](../remote-hardware-debug-flow.md)

## 工程边界

Liakia 是公开 showcase 和工作流模板，不是生产验收记录、安全认证、EMC 报告，也不替代工程签字。

客户交付时，应在目标硬件上重新生成原始 bench logs，包括：

- STM32CubeProgrammer transcript；
- serial shell transcript；
- protocol parser summary；
- register dump；
- artifact hashes；
- timestamps；
- handoff summary。

## 专业展示页面

- [专业展示页面](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.zh-CN.html)

## 下一步

如果你想把这套流程接入自己的固件项目，继续看：

- [Adopt it / 接入项目](../adopt-it/README.zh-CN.md)
