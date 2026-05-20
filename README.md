# dpiny-RTK - AI-Native Embedded Delivery Workflow Demo

[Chinese README](README.zh-CN.md) | English

This repository is a public showcase for a **human-in-the-loop AI workflow for embedded firmware delivery**.

It uses a real STM32F407 + UM982 RTK base-station firmware as the hardware case, but the core idea is broader:

```text
requirement -> code change -> build -> flash -> serial tests
-> protocol gates -> register probe -> evidence package -> handoff
```

**The RTK firmware is the case study. The workflow is the product.**

[![AI Embedded Workflow Demo](docs/promo-demo/preview.en.svg)](https://sailiono.github.io/dpiny-rtk-ai-workflow/promo-demo/index.en.html)

## Interactive Demo

- English page: [https://sailiono.github.io/dpiny-rtk-ai-workflow/promo-demo/index.en.html](https://sailiono.github.io/dpiny-rtk-ai-workflow/promo-demo/index.en.html)
- Chinese page: [https://sailiono.github.io/dpiny-rtk-ai-workflow/](https://sailiono.github.io/dpiny-rtk-ai-workflow/)
- Demo source: [docs/promo-demo/](docs/promo-demo/)

The English page is also available through the Pages redirect at:

```text
https://sailiono.github.io/dpiny-rtk-ai-workflow/index.en.html
```

## 30-Second Summary

Embedded firmware delivery often still depends on local IDE builds, manual flashing, hand-operated serial checks, scattered debug notes, and bringup knowledge that is hard to replay.

This repository shows how those manual steps can be turned into a repeatable delivery loop:

- build firmware from the command line;
- flash and verify the target over SWD;
- test serial shell behavior automatically;
- validate RTCM output with a CRC gate;
- verify USB CDC reset recovery;
- collect read-only register-level evidence;
- generate handoff evidence packages;
- keep AI actions inside explicit human review boundaries.

This is not a claim that AI should blindly replace embedded engineers. The intended model is:

```text
AI accelerates implementation, log analysis, test generation, and documentation.
Engineers keep ownership of hardware assumptions, safety boundaries, code review, and final acceptance.
```

## What This Repo Demonstrates

The reference firmware is an STM32F407-based RTK base-station controller with a UM982 GNSS/RTK module. The firmware itself is useful, but the showcase is designed to demonstrate the surrounding delivery system:

| Capability | What is demonstrated |
|---|---|
| Build automation | CMake presets, Ninja, Arm GCC, reproducible command-line build entry |
| Flash automation | STM32CubeProgrammer CLI over SWD with verify and reset |
| Serial regression | PowerShell scripts for shell commands, configuration, and validation gates |
| Protocol validation | RTCM3 frame parser with CRC-24Q checking and non-zero failure exit codes |
| USB CDC recovery | Reset recovery gate that verifies the shell still responds after software reset |
| Register evidence | Read-only SWD HotPlug probe for RCC, GPIO, USART, USB, and fault registers |
| Evidence package | Manifest, logs, JSON summaries, artifact hashes, stage timestamps, and handoff notes |
| Remote HIL | Redacted remote bench run where build, flash, tests, and evidence pullback happen on a bench PC |
| AI operating model | Playbooks and checklists that define what AI may do and where engineers must review |

## Why It Matters

For an embedded team, the value is not only faster coding. The stronger value is turning a fragile manual workflow into something that can be reviewed, replayed, handed over, and improved.

For engineering managers:

- each change can produce build, flash, test, register, and handoff evidence;
- failed tests become structured artifacts instead of chat history;
- bringup knowledge becomes easier to transfer to another engineer;
- remote bench work becomes auditable instead of ad hoc.

For embedded engineers:

- the workflow does not replace HAL, FreeRTOS, CMake, CubeCLT, ST-LINK, or serial debugging habits;
- it wraps familiar tools into a repeatable loop;
- protocol and register checks reduce guesswork during failure analysis;
- AI suggestions are grounded in logs, register values, and test outputs.

For business owners:

- delivery risk is reduced because failures become gates and regression cases;
- remote hardware-in-the-loop makes it easier to work with lab hardware without moving the board;
- evidence packages make technical progress easier to review without reading every line of code.

## Reference Firmware Case

Firmware source lives under:

```text
firmware/dpiny-rtk/
```

The root CMake entry remains available:

```powershell
cmake --preset Debug
cmake --build --preset Debug
```

Main firmware elements:

- STM32F407VET6, Cortex-M4F;
- FreeRTOS task model;
- UM982 GNSS/RTK module integration;
- USB CDC shell;
- USART debug shell;
- dual RS422 RTCM output path;
- flash-backed configuration;
- watchdog strategy;
- RTCM message configuration and CRC validation.

The firmware is intentionally kept as a real embedded case rather than a synthetic toy project. It includes enough hardware interaction to exercise build, flash, serial, protocol, USB, and register-level diagnosis.

## Baseline Runner

The reference workflow runner is:

```powershell
tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM4 -RtcmPort COM6 -UsbPort COM7
```

It can run:

- dependency checks;
- Debug firmware build;
- SWD flash and verify;
- functional shell regression;
- input validation gate;
- RTCM stream parser and CRC gate;
- USB CDC reset recovery gate;
- read-only register probe;
- manifest and JSON summary generation.

If `-UsbPort` is omitted, the manifest records `SKIP_NO_USB_PORT` instead of silently hiding the USB CDC reset gate.

Component runners are also available:

```powershell
tools/functional_test.ps1 -BuildPreset Debug -ComPort COM4
tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10 -OutputJson evidence-out/rtcm_summary.json
tools/usb_cdc_reset_test.ps1 -UsbPort COM7
tools/register_probe.ps1 -Target rcc,gpio,usart,usb,fault -OutputJson evidence-out/register_probe_summary.json
```

## Evidence Packages

The repository includes redacted evidence packages so that readers can inspect the delivery loop without needing the original bench hardware.

| Package | Type | Purpose | Result |
|---|---|---|---|
| [public-showcase-baseline-2026-05-18](evidence/public-showcase-baseline-2026-05-18/) | Public showcase sample | Shows the evidence format and public-safe register decode examples | PASS |
| [realrun-redacted-2026-05-20](evidence/realrun-redacted-2026-05-20/) | Local bench run | Shows a real hardware baseline with sensitive bench details removed | PASS |
| [remote-hil-redacted-2026-05-20](evidence/remote-hil-redacted-2026-05-20/) | Remote hardware-in-the-loop run | Shows remote build, flash, serial gates, RTCM CRC, USB CDC reset recovery, and evidence pullback | PASS |

See the evidence index: [evidence/README.md](evidence/README.md).

Typical evidence contents:

```text
00_manifest.json
01_environment_check.log
02_build_debug.log
03_flash_verify.log
04_shell_test.log
05_rtcm_parse.log
06_register_probe.log
firmware_sha256.txt
test_summary.md
handoff_report.md
```

The public evidence is intentionally redacted. A customer handoff should regenerate raw bench logs, serial transcripts, STM32CubeProgrammer output, register dumps, artifact hashes, and timestamps on the target hardware.

## Failure-To-Fix Case Studies

The case studies focus on how a failure becomes a diagnosis path, a minimal fix, and a regression gate.

| Case | Evidence level | What it shows |
|---|---|---|
| [USART clock missing](case-studies/01-usart-clock-missing.md) | Medium-high public replay | Register evidence can separate clock-enable issues from wiring or baud-rate guesses |
| [RS422 DE timing](case-studies/02-rs422-de-timing.md) | Diagnosis pattern | Driver-enable timing should be verified as a transport-layer failure mode |
| [RTCM CRC validation](case-studies/03-rtcm-crc-validation.md) | Validation pattern | Protocol gates should fail on zero frames, CRC errors, or missing message types |
| [USB CDC reset recovery](case-studies/04-usb-cdc-reset-recovery.md) | High, real bench replay | A reset-related USB CDC failure became a repeatable regression gate |

Case 04 is currently the strongest public case because it is tied to a real bench replay and the baseline runner now includes the USB CDC recovery gate.

## Remote Hardware-In-The-Loop

The remote HIL flow keeps the target board, ST-LINK, USB CDC port, UART shell, and RTCM adapter connected to a bench PC. The developer triggers build, flash, serial tests, protocol gates, and evidence pullback remotely.

This avoids moving the hardware while still preserving a real hardware loop:

```text
developer workstation
  -> remote bench command
  -> build on bench PC
  -> flash target through local ST-LINK
  -> run local serial and RTCM gates
  -> pull back evidence package
```

The public repository includes only redacted host information.

See: [docs/remote-hardware-debug-flow.md](docs/remote-hardware-debug-flow.md)

## Reusable Workflow Template

The reusable template lives in:

```text
workflow-template/
```

It demonstrates how another STM32 project can describe build, flash, tests, register probes, and evidence output through an adapter-driven workflow.

Example:

```powershell
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage all
```

The template is intentionally conservative:

- it does not force a new IDE;
- it does not require a new firmware framework;
- it can run tests as subprocesses so failed gates still generate evidence;
- it separates build, flash, test, probe, and evidence stages;
- it records summaries in a manifest suitable for handoff review.

## AI Agent Operating Model

The AI agent playbook lives in:

```text
ai-agent/
```

It defines:

- what the AI may do;
- what the AI must not do;
- when a human must review;
- pre-flash and pre-commit checklists;
- failure triage report templates;
- rules for keeping fixes minimal and evidence-backed.

This matters because embedded projects can damage hardware or create safety issues if automation crosses the wrong boundary. The repository frames AI as an engineering assistant inside a controlled workflow, not as an unchecked autonomous operator.

## ROI Model

The public ROI estimate for this case is roughly:

- AI-assisted delivery: about 3 person-days plus around 10 CNY API spend;
- conservative manual estimate: about 15-25 person-days;
- rough cycle reduction: 80%+ under this project's assumptions.

Boundary note: these numbers assume:

- an existing hardware platform;
- an existing STM32/HAL foundation;
- a scope focused on firmware bringup, automated validation, and evidence archiving;
- no PCB redesign, EMC qualification, environmental testing, safety certification, or production fixture development.

They do not imply the same ratio for all embedded projects.

See: [docs/roi_model.md](docs/roi_model.md)

## Commercial Use Cases

The workflow is meant to be portable beyond this RTK example.

Potential use cases:

- STM32 board bringup automation;
- firmware regression test loops;
- AI-assisted failure diagnosis;
- engineering handoff evidence packages;
- remote hardware-in-the-loop debugging;
- legacy firmware engineering cleanup;
- customer-site issue reproduction and regression proof.

See: [docs/commercial-use-cases.md](docs/commercial-use-cases.md)

## Repository Layout

```text
firmware/dpiny-rtk/       Reference STM32 firmware case
tools/                    Baseline runner, serial tests, RTCM parser, register probe
workflow-template/        Adapter-driven reusable workflow scaffold
evidence/                 Public showcase, local bench, and remote HIL evidence packages
case-studies/             Failure-to-fix and diagnosis case studies
ai-agent/                 AI operation contract, checklists, and templates
docs/promo-demo/          Interactive web showcase, Chinese and English pages
docs/                     ROI, commercial use cases, demo video script, remote HIL notes
```

## What This Project Is Not

This repository is not:

- a production acceptance record;
- a certification package;
- an EMC, ESD, safety, or environmental qualification report;
- a replacement for engineering review;
- a promise that every embedded project can be compressed by the same ratio.

It is a public showcase of a repeatable embedded delivery workflow, backed by a real firmware case and redacted bench evidence.

## License

Copyright (c) 2026 **Clark Cui**. All rights reserved.
