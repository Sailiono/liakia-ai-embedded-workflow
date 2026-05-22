# AI Diagnosis Playbook

This document defines how to give Starter-F103 evidence to an AI assistant, and how the assistant should constrain its reasoning.

## Poor Prompt

```text
My sensor does not work. Please help.
```

This is under-specified. The assistant can only guess.

## Recommended Input Structure

```text
Goal:
  I am running known-bad Case A in the STM32F103C8T6 + BMP280 lab.

Hardware:
  MCU: STM32F103C8T6
  Sensor: BMP280
  I2C: I2C1 PB6/PB7 100 kHz
  UART: USART1 PA9/PA10 115200
  Debug: ST-LINK SWD

Current symptoms:
  sensor id PASS
  raw sensor/protocol bytes are readable
  one later data-quality gate fails
  data-quality gate FAIL

Logs:
  Paste version / diag i2c / sensor id / sensor read / telemetry once output.

Relevant code:
  Paste the imported known-bad app-layer file or the smallest suspicious functions.

Constraints:
  First inspect the application layer.
  Do not assume broken hardware unless evidence supports it.
  Do not perform unrelated refactors.
  List what still needs human confirmation.
```

## Required AI Output Format

Ask the assistant to answer in this structure:

```markdown
## Observations

- Confirmed facts
- Unconfirmed facts

## Ruled Out

- Directions excluded by evidence

## Hypotheses

| Rank | Hypothesis | Evidence | How to confirm |
|---|---|---|---|

## Minimal Fix

- File to change
- Change point
- What must not be changed

## Regression Plan

- Gates to rerun
- PASS criteria
```

## Case A Example Prompt

```text
You are an embedded firmware debugging assistant. Analyze only from evidence. Do not invent broken hardware claims.

Project: Liakia Starter-F103 Sensor Lab
Hardware: STM32F103C8T6 + BMP280
Interfaces: I2C1 PB6/PB7, 100 kHz; USART1 PA9/PA10, 115200

Symptoms:
- version PASS
- diag i2c found 0x76
- sensor id returns 0x58 PASS
- raw sensor bytes are readable
- a later data-quality gate FAILs
- data-quality gate FAIL

Please analyze:
1. what can be ruled out;
2. the top 3 likely root causes;
3. which code snippets should be inspected;
4. where the minimal fix should be;
5. which gates to rerun after the fix.

Constraints:
- Do not change IOC unless evidence points to low-level configuration.
- Do not rewrite the whole driver.
- Rank hypotheses from evidence instead of jumping to a predefined answer.
```

## Human Review Boundary

AI may suggest:

- code paths to inspect;
- datasheet register and formula comparisons;
- test scripts;
- log and register interpretations;
- minimal fixes.

AI must not directly decide to:

- change hardware wiring;
- raise supply voltage;
- disable protective gates;
- change Flash addresses;
- change SWD / BOOT configuration;
- skip failed gates and mark the run PASS.

## Evidence Priority

| Priority | Evidence | Use |
|---|---|---|
| P0 | Automated test output | Identify failed gate |
| P0 | Raw serial log | Inspect actual command responses |
| P1 | Raw sensor bytes | Separate bus issues from algorithm issues |
| P1 | Register snapshot | Separate peripheral configuration from application logic |
| P2 | Logic analyzer capture | Handle I2C/UART timing and intermittent issues |
| P2 | Code diff | Confirm fix scope |
