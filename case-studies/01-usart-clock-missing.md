# Case 01 — USART Clock Missing

## 1. Background

- Platform: STM32F407 + FreeRTOS
- Interface: USART2 / USART3 debug or RS422 path
- Stage: bringup and serial validation

## 2. Symptom

- Build passed.
- Flash and reset passed.
- MCU was running.
- Serial output was missing or unstable.
- Shell / RS422 channel did not respond as expected.

## 3. Initial Hypotheses

- GPIO alternate-function mapping error.
- USART peripheral clock not enabled.
- Baudrate mismatch.
- TX/RX route mismatch.
- RS422 DE timing issue.
- Task not started.

## 4. Automated Diagnosis

Example probe command:

```powershell
tools/register_probe.ps1 -Target usart
```

Registers to capture:

```text
RCC_APB1ENR
RCC_APB2ENR
GPIOD_MODER
GPIOD_AFRL
USART2_BRR
USART2_CR1
USART2_SR
```

## 5. AI Analysis Summary

The AI compares register evidence with expected peripheral state:

- GPIO alternate-function mode is present.
- Baudrate register is plausible.
- USART enable path is incomplete.
- RCC peripheral clock bit is missing or inconsistent.

Likely root cause: USART peripheral clock enable was missing or initialization order was wrong.

## 6. Human Confirmation

The engineer reviews CubeMX/HAL initialization and confirms whether the clock-enable macro is present before USART initialization.

## 7. Fix

Typical fix location:

```text
Core/Src/usart.c
Core/Src/main.c
```

Typical fix:

```c
__HAL_RCC_USART2_CLK_ENABLE();
__HAL_RCC_USART3_CLK_ENABLE();
```

## 8. Regression

```powershell
tools/test_shell.ps1 -Port COM4
tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10
```

Expected:

```text
Shell test: PASS
RTCM parse: PASS
CRC bad: 0
```

## 9. Value

The workflow reduces diagnosis time by quickly separating wiring, GPIO mode, baudrate, clock tree, and task scheduling hypotheses.
