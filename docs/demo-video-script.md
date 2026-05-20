# FirmwareProof 3-Minute Demo Video Script

## 0:00 - 0:20 — Pain

Show the traditional embedded workflow:

- local IDE build;
- manual flashing;
- manual serial testing;
- undocumented failure diagnosis;
- hard-to-replay bringup history.

Narration:

> Embedded delivery often fails not because the code cannot be written, but because the process is difficult to reproduce and hand off.

## 0:20 - 0:40 — Project Goal

Show the repository and the interactive page.

Narration:

> FirmwareProof uses dpiny-RTK, an STM32F407 + UM982 RTK firmware, as a real hardware case to demonstrate an AI-assisted build-flash-test-debug-report loop.

## 0:40 - 1:10 — One Command

Show a terminal running the baseline command.

```powershell
tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM4 -RtcmPort COM6 -UsbPort COM7
```

Highlight:

- CMake / Ninja build;
- STM32CubeProgrammer flash;
- shell test;
- RTCM parser;
- USB CDC reset recovery gate.

## 1:10 - 1:40 — Evidence

Show `evidence/public-showcase-baseline-2026-05-18/`.

Highlight:

- manifest;
- build log;
- flash log;
- shell test log;
- RTCM CRC log;
- handoff report.

## 1:40 - 2:20 — Fault Case

Show one case study, such as USART clock missing.

Narration:

> The workflow is valuable not only on the happy path. The real value appears when the hardware does not behave as expected.

## 2:20 - 2:45 — AI-Assisted Diagnosis

Show register probe evidence and AI summary.

Highlight:

- GPIO AF mode checked;
- USART clock bit checked;
- root cause proposed;
- engineer confirms.

## 2:45 - 3:00 — Regression

Show tests passing again.

Narration:

> AI helps compress repetitive work, but the engineer remains responsible for review and acceptance.
