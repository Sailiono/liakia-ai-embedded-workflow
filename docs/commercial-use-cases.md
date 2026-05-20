# BenchLoop Commercial Use Cases

BenchLoop is a transferable workflow case, not only a single RTK firmware project.

## 1. STM32 Board Bringup Automation

Suitable for:

- industrial data-acquisition boards;
- sensor gateways;
- communication interface boards;
- motor-control peripherals;
- flight-controller extension modules.

Delivery scope:

- CMake / CubeCLT build integration;
- SWD flash and verify command;
- serial shell test scripts;
- register diagnosis templates;
- evidence package;
- handoff report.

## 2. Firmware Regression Workflow

Suitable for:

- multi-version firmware maintenance;
- small-batch product iteration;
- customer-site bug fixes;
- legacy project engineering cleanup.

Delivery scope:

- serial protocol tests;
- frame/CRC parsers;
- test summary templates;
- version and artifact tracking;
- repeatable regression command.

## 3. AI-Assisted Fault Diagnosis

Suitable for:

- HardFault triage;
- UART no-output issues;
- DMA idle-line and ring-buffer issues;
- USB CDC enumeration failure;
- watchdog reset loops;
- peripheral clock or GPIO alternate-function mistakes.

Delivery scope:

- failure capture scripts;
- register probe targets;
- AI analysis playbook;
- human confirmation checklist;
- post-fix regression tests.

## 4. Handoff Evidence For Engineering Teams

Suitable for:

- teams that need reviewable test proof;
- outsourced firmware delivery;
- internal platform teams supporting product teams;
- engineering managers who need a reproducible project record.

Delivery scope:

- manifest;
- build log;
- flash verification log;
- serial functional test log;
- register probe log;
- handoff summary.

## 5. Remote Hardware-In-The-Loop Debugging

Suitable for:

- shared hardware benches;
- remote labs and field-return devices;
- teams where firmware, hardware, and test engineers are not in the same room;
- scarce prototypes that should not be moved between desks.

Public proof point:

- [Remote HIL evidence 2026-05-20](../evidence/remote-hil-redacted-2026-05-20/) shows a redacted remote run with build, flash, serial tests, RTCM CRC gate, USB CDC reset recovery, and evidence pullback all passing.

Delivery scope:

- remote bench command entry;
- build / flash / serial / RTCM / USB CDC test loop;
- failed-run log retention;
- redacted evidence package;
- post-fix regression proof.
