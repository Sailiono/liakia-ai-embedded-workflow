# Liakia Starter-F103 Sensor Lab

[中文说明](README.zh-CN.md)

This lab is the hands-on entry point for Liakia.

The main repository proves that Liakia can run an evidence-backed delivery loop on a real STM32F407 + RTK firmware project. This starter lab serves a different purpose: it lets a new user build a small STM32F103C8T6 bench, import intentionally broken application code, and experience the same evidence-first diagnosis loop on hardware they can assemble themselves.

Start here if you want to run it:

[Quick start](quick-start.md)

## Why This Lab Exists

A public showcase dan prove that the workflow worked once. It does not prove that a new user understands the method.

This lab closes that gap. Instead of shipping a complete prebuilt firmware image, it asks the user to:

1. wire a low-cost F103 board;
2. create the STM32CubeMX IOC;
3. generate their own HAL project;
4. integrate the Liakia application layer;
5. flash a known-good baseline;
6. import a known-bad case folder;
7. collect evidence from a failing run;
8. ask AI to diagnose only from evidence;
9. apply the minimal fix;
10. rerun the regression gates.

The learning value is in doing the loop, not in watching a canned demo print PASS.

## The Mental Model

Liakia does not replace the user's embedded project. It wraps a project with repeatable gates and evidence.

| Layer | Owned by | Purpose |
|---|---|---|
| Hardware wiring | User | SWD, UART, I2C, sensor power, shared ground |
| IOC / HAL generation | User | Real STM32CubeMX project, not a prebuilt firmware image |
| Application layer | Liakia starter kit | Shell commands, BMP280 checks, telemetry, known-bad imports |
| Test gates | Liakia tools | Build, flash, shell, sensor, protocol, reset, register probe |
| Diagnosis | User + AI | Evidence-scoped debugging and minimal fix review |
| Regression | User + Liakia tools | Confirm the fix with the same gates and archive results |

## What You Will Experience

The first run should be boring:

```text
wire board -> generate IOC -> add app layer -> build -> flash -> sensor gate PASS
```

The known-bad run should fail in a controlled way:

```text
import case folder -> build -> flash -> gate FAIL -> evidence package generated
```

The final run should prove the fix:

```text
AI diagnosis -> human review -> minimal code fix -> same gates PASS -> manifest archived
```

That is the Liakia workflow in miniature.

## Recommended First Path

Use the baseline path first:

[quick-start.md](quick-start.md)

Then import the first case pack:

[known-bad-cases/case-a-bmp280-calibration/README.md](known-bad-cases/case-a-bmp280-calibration/README.md)

Do not read the case answer key until you have reproduced the failure and generated the AI diagnosis packet.

## Case Packs

Each known-bad case is a folder, not just a write-up. The folder includes broken code to import, a practice guide, and a separate answer key.

| Case | What you import | Best for |
|---|---|---|
| [Case A: BMP280 data quality failure](known-bad-cases/case-a-bmp280-calibration/README.md) | Complete `liakia_lab_app.c` replacement | First real run |
| [Case B: I2C reset recovery failure](known-bad-cases/case-b-i2c-bus-stuck-reset/README.md) | Port-layer replacement | Reset-state reasoning |
| [Case C: Flash persistence failure](known-bad-cases/case-c-flash-persistence-alignment/README.md) | Config persistence fragment | Reset and raw-record evidence |
| [Case D: UART DMA/IDLE stream failure](known-bad-cases/case-d-uart-dma-idle-race/README.md) | DMA/IDLE receive fragment | Advanced serial diagnosis |

## Hardware Target

Recommended low-cost setup:

| Item | Role |
|---|---|
| STM32F103C8T6 Blue Pill compatible board | Target MCU board |
| ST-LINK compatible probe | SWD flash and read-only register access |
| USB-TTL 3.3 V adapter | USART1 shell and telemetry capture |
| BMP280 module | I2C sensor with chip ID, raw values, and data-quality checks |
| 4.7k pull-up resistors | Optional I2C pull-ups if the module does not include them |
| Jumper wires | SWD, UART, I2C, and common ground |

## Documents

| Document | Purpose |
|---|---|
| [Quick start](quick-start.md) | Complete path from wiring to known-bad diagnosis and regression |
| [BOM](bom.md) | Parts and selection notes |
| [Wiring](wiring.md) | SWD, UART, and I2C wiring |
| [CubeMX / IOC guide](cubemx-ioc-guide.md) | User-generated IOC checkpoints |
| [Application layer contract](app-layer/README.md) | How to integrate Liakia application code into generated HAL code |
| [Known-bad case packs](known-bad-cases/README.md) | Importable broken code, practice guides, and answer keys |
| [Test gates](test-gates.md) | PASS / FAIL criteria for shell, sensor, protocol, reset, and evidence gates |
| [Diagnosis playbook](diagnosis-playbook.md) | How to give evidence to an AI assistant without turning debugging into guessing |
| [Evidence template](evidence-template/README.md) | Manifest, log, and summary examples |
| [Troubleshooting](troubleshooting.md) | Common hardware, UART, I2C, and reset failures |
| [Tools](tools/) | Starter runner, F103 register probe, and diagnosis prompt generation |

## Success Criteria

The lab is successful when the user can show:

- a working normal F103 + BMP280 baseline;
- at least one known-bad case imported from a case folder;
- a failing gate with evidence archived;
- an AI diagnosis prompt generated from that evidence;
- a minimal fix;
- a new regression run that passes.

This proves that the user has not only seen Liakia, but has used its workflow.

## Boundary

This starter lab is not a complete product firmware and does not replace the dpiny-RTK engineering case. It is a training bench and adoption path for the workflow. The professional proof remains the STM32F407 + RTK evidence packages; the starter lab makes the method learnable.
