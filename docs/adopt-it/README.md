# Adopt It — Bring Liakia To Your STM32 Project

[中文说明](README.zh-CN.md) | English

This path is for teams that already have an STM32 firmware project and want to turn repeated manual delivery steps into a build / flash / test / evidence loop.

Liakia is designed to wrap your current stack. It does not require replacing HAL, FreeRTOS, CubeCLT, ST-LINK, serial tools, or your existing debug habits.

## Suitable Projects

- STM32 board bringup;
- industrial acquisition boards;
- sensor gateways;
- communication adapter boards;
- flight-control peripherals;
- field bug reproduction;
- remote bench regression.

## What You Provide

| Input | Example |
|---|---|
| Firmware repo | Git checkout or source package |
| Build command | `cmake --build --preset Debug` |
| Flash method | STM32CubeProgrammer CLI over SWD |
| Serial interfaces | shell port, debug port, protocol output port |
| Expected commands | `version`, `status`, `config`, project-specific commands |
| Protocol output | RTCM, binary frames, ASCII telemetry, Modbus-like output, etc. |
| Hardware risk notes | power, boot mode, reset behavior, destructive commands to avoid |

## One-Week Pilot Shape

| Day | Goal |
|---:|---|
| 1 | Make build and artifact discovery scriptable. |
| 2 | Add flash / verify / reset transcript collection. |
| 3 | Add shell smoke tests and serial evidence. |
| 4 | Add protocol gate and failure evidence. |
| 5 | Add register probe, evidence manifest, and handoff review. |

The exact scope depends on board availability, hardware risk, protocol complexity, and existing test coverage.

## Integration Model

Liakia uses an adapter-driven model:

```text
project adapter
  -> build command
  -> flash command
  -> serial tests
  -> protocol gates
  -> optional register probe
  -> evidence manifest
```

Start with:

- [Adapt your STM32 project](../adapt-your-stm32-project.md)
- [workflow-template](../../workflow-template/)

## What Is Not Included By Default

- PCB redesign;
- EMC/ESD validation;
- safety certification;
- production test fixtures;
- replacement of your firmware architecture;
- final acceptance without human review.

## Adoption Page

- [Professional page](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/professional.en.html#adopt)

## Before Adoption

If your team wants to inspect existing proof first, read:

- [Trust it](../trust-it/README.md)
