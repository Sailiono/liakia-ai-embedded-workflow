# Trust It — Engineering Proof

[中文说明](README.zh-CN.md) | English

This path is for engineers, CTOs, engineering managers, and technically minded customers who want to verify that Liakia is more than a narrative.

The proof is not a slide. It is a set of redacted evidence packages, failure-to-fix cases, scripts, and workflow boundaries from a real STM32 firmware project and a remote hardware-in-the-loop bench.

## What To Verify First

| Question | Public proof |
|---|---|
| Does the workflow run on real hardware? | [realrun-redacted-2026-05-20](../../evidence/realrun-redacted-2026-05-20/) |
| Can it run through a remote bench PC? | [remote-hil-redacted-2026-05-20](../../evidence/remote-hil-redacted-2026-05-20/) |
| Does a protocol gate fail objectively? | [RTCM parser](../../tools/rtcm_parse.ps1) |
| Is USB CDC reset recovery covered? | [Case 04](../../case-studies/04-usb-cdc-reset-recovery.md) |
| Is register-level evidence available? | [register_probe.ps1](../../tools/register_probe.ps1) |
| Is AI constrained by human review? | [AI agent playbook](../../ai-agent/) |

## Evidence Packages

| Package | Type | Purpose | Result |
|---|---|---|---|
| [public-showcase-baseline-2026-05-18](../../evidence/public-showcase-baseline-2026-05-18/) | Public format sample | Evidence structure and public-safe decode examples | PASS |
| [realrun-redacted-2026-05-20](../../evidence/realrun-redacted-2026-05-20/) | Local bench run | Real hardware baseline with sensitive bench details removed | PASS |
| [remote-hil-redacted-2026-05-20](../../evidence/remote-hil-redacted-2026-05-20/) | Remote HIL run | Remote build, flash, serial gates, RTCM CRC, USB CDC reset recovery, and evidence pullback | PASS |

Typical files to inspect:

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

## Featured Case

The strongest public case is:

- [Case 04 — USB CDC Shell Recovery After Software Reset](../../case-studies/04-usb-cdc-reset-recovery.md)

It shows the important engineering pattern: a failure is not only fixed once; it becomes a repeatable regression gate in the baseline runner.

## Remote HIL

Remote HIL keeps the target board, ST-LINK, USB CDC port, UART shell, and RTCM adapter on the bench PC. The developer triggers the workflow remotely, and evidence is generated on the machine physically connected to the hardware.

Read:

- [Remote hardware debug flow](../remote-hardware-debug-flow.md)

## Engineering Boundaries

Liakia is a public showcase and workflow template. It is not a production acceptance record, safety certification, EMC report, or substitute for engineering sign-off.

For customer delivery, raw bench logs should be regenerated on the target hardware, including:

- STM32CubeProgrammer transcript;
- serial shell transcript;
- protocol parser summary;
- register dump;
- artifact hashes;
- timestamps;
- handoff summary.

## Professional Page

- [Professional page](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.en.html)

## Next

If you want to integrate the workflow into your own firmware project, continue to:

- [Adopt it](../adopt-it/README.md)
