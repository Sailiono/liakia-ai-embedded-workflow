# Liakia Starter-F103 Sensor Lab

This starter lab is the hands-on entry point for Liakia.

If you want to run the lab, start here:

```text
quick-start.md
```

This folder contains the hardware, wiring, IOC, application layer, known-bad case, test gates, diagnosis, and evidence documents needed to complete the F103 lab.

It is intentionally separate from the dpiny-RTK engineering case:

| Path | Audience | Purpose |
|---|---|---|
| Starter-F103 Sensor Lab | New users, evaluators, junior engineers | Build a low-cost STM32F103C8T6 bench and experience a real debug loop |
| dpiny-RTK Engineering Case | Embedded engineers | Inspect a real STM32F407 + RTK delivery workflow with evidence packages |
| Workflow Template | Team leads, consultants | Adapt the build / flash / test / evidence loop to another STM32 project |

## What This Lab Does

The user creates the STM32CubeMX IOC project and generated HAL code. Liakia provides:

- a guided STM32F103C8T6 hardware wiring path;
- IOC configuration checkpoints so the generated project stays on track;
- application-layer code that can be integrated into the generated project;
- known-bad application cases with realistic embedded failure modes;
- test and diagnosis expectations for build, flash, shell, sensor, reset, protocol, and evidence gates.

The goal is not to hide embedded complexity. The goal is to make it reproducible.

## Hardware Target

Recommended low-cost setup:

| Item | Role |
|---|---|
| STM32F103C8T6 Blue Pill compatible board | Target MCU board |
| ST-LINK compatible probe | SWD flash and debug access |
| USB-TTL adapter | UART shell and telemetry capture |
| BMP280 module | I2C sensor with ID, calibration, and compensation path |
| 4.7k pull-up resistors | Optional I2C pull-ups if the module does not include them |
| Jumper wires | SWD, UART, I2C, and common ground |

## Learning Flow

```text
Create IOC manually
  -> Generate HAL project
  -> Add Liakia application layer
  -> Build
  -> Flash through ST-LINK
  -> Run serial shell tests
  -> Run BMP280 protocol gates
  -> Trigger a known-bad failure
  -> Collect logs and register evidence
  -> Fix the application layer
  -> Re-run regression
  -> Generate evidence package
```

## Lab Documents

| Document | Purpose |
|---|---|
| [Quick start](quick-start.md) | Complete English path from wiring to known-bad diagnosis and regression |
| [中文快速上手](quick-start.zh-CN.md) | 同一实验的中文快速上手 |
| [Chinese guide](README.zh-CN.md) | Main hands-on guide |
| [BOM](bom.md) | Parts and selection notes |
| [Wiring](wiring.md) | SWD, UART, and I2C wiring |
| [CubeMX / IOC guide](cubemx-ioc-guide.md) | User-generated IOC checkpoints |
| [Missions](missions/README.md) | Step-by-step lab story |
| [Known-bad cases](known-bad-cases/README.md) | Realistic failure modes for AI-assisted diagnosis |
| [Application layer contract](app-layer/README.md) | How to integrate Liakia application code into generated HAL code |
| [F103 HAL port template](app-layer/port-template/) | Platform bridge template for generated CubeMX projects |
| [Test gates](test-gates.md) | PASS / FAIL criteria for shell, sensor, protocol, reset, and evidence gates |
| [Diagnosis playbook](diagnosis-playbook.md) | How to give evidence to an AI assistant without turning debugging into guessing |
| [Evidence template](evidence-template/README.md) | Manifest, log, and summary examples |
| [Troubleshooting](troubleshooting.md) | Common hardware, UART, I2C, and reset failures |
| [Tools](tools/) | Starter runner, F103 register probe, and diagnosis prompt generation |
| [Automation plan](future-automation.md) | Follow-up enhancements |

## Boundary

This starter lab is a project adapter and application-layer exercise. It does not ship a complete STM32CubeMX project because the learning value is in creating the IOC, generating the HAL code, and then using Liakia to debug the application-level failures on top of that generated base.
