# dpiny-RTK — AI-Native Embedded Delivery Workflow Demo

[中文说明](README.zh-CN.md) | English

This repository demonstrates a **human-in-the-loop AI workflow for embedded firmware delivery**.

It uses an STM32F407 + UM982 RTK base-station firmware as a real hardware case, but the core product is the delivery workflow:

```text
requirement -> code change -> build -> flash -> serial tests
-> protocol gates -> register probe -> evidence package -> handoff
```

**The RTK firmware is the case study. The workflow is the product.**

[![AI Embedded Workflow Demo](docs/promo-demo/preview.svg)](https://sailiono.github.io/dpiny-rtk-ai-workflow/)

## Interactive Demo

- Chinese page: [https://sailiono.github.io/dpiny-rtk-ai-workflow/](https://sailiono.github.io/dpiny-rtk-ai-workflow/)
- English page: [https://sailiono.github.io/dpiny-rtk-ai-workflow/index.en.html](https://sailiono.github.io/dpiny-rtk-ai-workflow/index.en.html)
- Demo source: [docs/promo-demo/](docs/promo-demo/)

## What This Repo Demonstrates

- Command-line firmware build with CMake, Ninja, and Arm GCC.
- SWD flash and verify through STM32CubeProgrammer CLI.
- Automated serial shell regression tests.
- RTCM3 frame parsing with CRC gate.
- USB CDC reset recovery validation.
- Read-only SWD register probe evidence.
- Redacted evidence packages for local and remote bench runs.
- A reusable adapter template for bringing the workflow to other STM32 projects.
- Human review boundaries for AI-assisted embedded work.

## Why It Matters

Traditional embedded delivery often depends on manual IDE builds, manual flashing, manual serial checks, scattered logs, and hard-to-replay bringup knowledge.

This repo shows how those steps can become a repeatable and auditable loop:

- **For engineering managers:** each change can produce build, flash, test, diagnosis, and handoff evidence.
- **For embedded engineers:** the workflow keeps HAL, FreeRTOS, CMake, CubeCLT, ST-LINK, and serial debugging habits intact.
- **For business owners:** delivery risk is reduced because failures become gates, logs, and regression cases instead of chat history.

## Evidence Packages

| Package | Type | Result |
|---|---|---|
| [public-showcase-baseline-2026-05-18](evidence/public-showcase-baseline-2026-05-18/) | Evidence format sample | PASS |
| [realrun-redacted-2026-05-20](evidence/realrun-redacted-2026-05-20/) | Redacted local bench run | PASS |
| [remote-hil-redacted-2026-05-20](evidence/remote-hil-redacted-2026-05-20/) | Redacted remote hardware-in-the-loop run | PASS |

See the evidence index: [evidence/README.md](evidence/README.md).

## Baseline Runner

Primary workflow runner:

```powershell
tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM4 -RtcmPort COM6 -UsbPort COM7
```

It can run:

- functional build / flash / shell tests;
- RTCM parser and CRC gate;
- USB CDC reset recovery gate;
- SWD register probe;
- manifest and JSON summary generation.

If `-UsbPort` is omitted, the manifest records `SKIP_NO_USB_PORT` instead of silently hiding the USB CDC reset gate.

## Firmware Case Study

Firmware source lives under:

```text
firmware/dpiny-rtk/
```

The root CMake entry remains available:

```powershell
cmake --build --preset Debug
```

Main firmware elements:

- STM32F407 + FreeRTOS;
- UM982 GNSS / RTK integration;
- USB CDC + USART shell;
- dual RS422 RTCM output;
- watchdog and flash-backed configuration;
- RTCM message configuration and CRC validation.

## Failure-To-Fix Cases

| Case | Evidence level |
|---|---|
| [USART clock missing](case-studies/01-usart-clock-missing.md) | Medium-high public replay |
| [RS422 DE timing](case-studies/02-rs422-de-timing.md) | Diagnosis pattern |
| [RTCM CRC validation](case-studies/03-rtcm-crc-validation.md) | Validation pattern |
| [USB CDC reset recovery](case-studies/04-usb-cdc-reset-recovery.md) | High, real bench replay |

Case 04 is the strongest public example: a reset-related USB CDC failure became a repeatable regression gate in the baseline runner.

## Remote Hardware-In-The-Loop

The remote HIL flow keeps the target board, ST-LINK, USB CDC port, UART shell, and RTCM adapter connected to a bench PC while the developer triggers build, flash, tests, and evidence pullback remotely.

See: [docs/remote-hardware-debug-flow.md](docs/remote-hardware-debug-flow.md)

## Workflow Template

The reusable template lives in:

```text
workflow-template/
```

It demonstrates how another STM32 project can describe build, flash, tests, register probes, and evidence output through an adapter-driven workflow.

## ROI Model

The public ROI estimate for this case is roughly:

- AI-assisted delivery: about 3 person-days plus around 10 CNY API spend;
- conservative manual estimate: about 15-25 person-days;
- rough cycle reduction: 80%+ under this project's assumptions.

Boundary note: these numbers assume an existing hardware platform, an existing STM32/HAL foundation, and a scope focused on firmware bringup, automated validation, and evidence archiving. They do not imply the same ratio for all embedded projects.

See: [docs/roi_model.md](docs/roi_model.md)

## Commercial Use Cases

- STM32 board bringup automation.
- Firmware regression test loops.
- AI-assisted failure diagnosis.
- Engineering handoff evidence packages.
- Remote hardware-in-the-loop debugging.

See: [docs/commercial-use-cases.md](docs/commercial-use-cases.md)

## Human-In-The-Loop Policy

AI assists with code changes, log analysis, test generation, and evidence packaging.

Engineers remain responsible for hardware assumptions, risk decisions, final code review, safety boundaries, and delivery acceptance.

See: [ai-agent/](ai-agent/)

## License

Copyright (c) 2026 **Clark Cui**. All rights reserved.
