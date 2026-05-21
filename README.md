# Liakia

**AI-Assisted Embedded Firmware Delivery Loop**

For STM32 teams that need repeatable build, flash, test, diagnose, evidence, and handoff.

[中文说明](README.zh-CN.md) | English

[![Workflow](https://img.shields.io/badge/Workflow-build_flash_test_evidence-80ff72)]()
[![MCU](https://img.shields.io/badge/MCU-STM32-blue)](https://www.st.com)
[![Mode](https://img.shields.io/badge/AI-Human--in--the--loop-54d7ff)]()
[![Evidence](https://img.shields.io/badge/Evidence-real_bench_%2B_remote_HIL-ffb84d)]()

Embedded firmware delivery often breaks in the gaps between code changes, hardware validation, and handoff evidence.

Liakia closes those gaps with a human-reviewed loop on real or remote STM32 hardware:

```text
build -> flash -> test -> diagnose -> evidence -> handoff
```

The repository uses **dpiny-RTK** as the engineering proof case and **Starter-F103 Sensor Lab** as the hands-on learning path.

**dpiny-RTK is the demo case. Liakia is the workflow.**

## What Is Liakia?

Liakia is not a firmware library and not a single RTK product. It is a workflow for making embedded firmware work reviewable and repeatable:

- build firmware from command line;
- flash and verify the target through SWD;
- run serial, protocol, reset, and register-level gates;
- generate evidence packages with logs, manifests, and summaries;
- let AI assist implementation and diagnosis while engineers keep final review authority.

## Choose Your Path

| Path | Use it when | Start |
|---|---|---|
| **Learn it** | You want a low-cost STM32F103 + BMP280 lab to experience AI-assisted debugging by yourself. | [docs/learn-it/README.md](docs/learn-it/README.md) |
| **Trust it** | You want to inspect real bench evidence, remote HIL proof, failure cases, and engineering boundaries. | [docs/trust-it/README.md](docs/trust-it/README.md) |
| **Adopt it** | You want to integrate the same build / flash / test / evidence loop into your own STM32 project. | [docs/adopt-it/README.md](docs/adopt-it/README.md) |

## Web Pages

| Page | Purpose |
|---|---|
| [Beginner page](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/beginner.en.html) | Hands-on STM32F103 learning path. |
| [Professional page](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.en.html) | Engineering proof, remote HIL, failure-to-fix case, and adoption path. |
| [Chinese landing page](https://sailiono.github.io/liakia-ai-embedded-workflow/) | Chinese router for beginner and professional readers. |

## Proof At A Glance

| Proof | Public artifact |
|---|---|
| Real local bench evidence | [evidence/realrun-redacted-2026-05-20/](evidence/realrun-redacted-2026-05-20/) |
| Remote hardware-in-the-loop evidence | [evidence/remote-hil-redacted-2026-05-20/](evidence/remote-hil-redacted-2026-05-20/) |
| USB CDC reset recovery case | [case-studies/04-usb-cdc-reset-recovery.md](case-studies/04-usb-cdc-reset-recovery.md) |
| RTCM CRC gate | [tools/rtcm_parse.ps1](tools/rtcm_parse.ps1) |
| Read-only register probe | [tools/register_probe.ps1](tools/register_probe.ps1) |
| Reusable adapter-driven workflow | [workflow-template/](workflow-template/) |

## Primary Commands

Reference baseline runner:

```powershell
tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM4 -RtcmPort COM6 -UsbPort COM7
```

Reusable workflow template:

```powershell
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage all
```

Starter-F103 lab runner:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

## Scope

Liakia is designed to compress repeatable firmware delivery work: build repair, flash verification, serial regression, protocol gates, log analysis, evidence packaging, and handoff preparation.

It does **not** replace schematic review, safety decisions, EMC/ESD work, production test fixture design, or final engineering approval.

## Repository Map

| Area | Purpose |
|---|---|
| [firmware/dpiny-rtk/](firmware/dpiny-rtk/) | Reference STM32F407 + UM982 RTK firmware case. |
| [starter-kits/stm32f103-sensor-lab/](starter-kits/stm32f103-sensor-lab/) | Low-cost hands-on lab with known-bad debugging cases. |
| [evidence/](evidence/) | Public, real bench, and remote HIL evidence packages. |
| [case-studies/](case-studies/) | Failure-to-fix case studies. |
| [workflow-template/](workflow-template/) | Adapter-driven workflow template for other STM32 projects. |
| [ai-agent/](ai-agent/) | Human-in-the-loop AI operation rules and checklists. |
| [docs/](docs/) | Learn, trust, adopt, ROI, commercial, and web documentation. |
