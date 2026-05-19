# Case 01 — USART Clock Missing Caused Serial Output Failure

This case is written as an evidence-grade public replay. It shows the structure expected in a customer handoff: symptom, failed test, register evidence, AI root-cause proposal, engineer confirmation, minimal fix, and regression proof.

Raw bench logs should be regenerated on the customer's target hardware. The register values below are public decode examples used to demonstrate the evidence format.

## 1. Incident Context

- Time: 2026-05-18 14:34 +08:00
- Platform: STM32F407 + FreeRTOS
- Affected path: USART2 / USART3 debug and RS422 output path
- Source firmware commit: `da023ee`
- Test entry: `tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10`

## 2. Symptom

- Build passed.
- Flash workflow gate passed.
- USB CDC Shell was reachable.
- RS422 path produced no valid RTCM frames.
- RTCM parser reported no frames and therefore failed the gate.

Failed test shape:

```text
$ tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10
Reading RTCM from COM6 for 10 seconds...
Read 0 bytes

=== RTCM Stream Analysis ===
Total frames found: 0
CRC OK: 0
CRC BAD: 0
[FAIL] no RTCM frames found
[RTCM-RESULT] FAIL
```

## 3. Initial Hypotheses

- GPIO alternate-function mapping error.
- USART peripheral clock not enabled.
- Baudrate mismatch.
- TX/RX route mismatch.
- RS422 DE timing issue.
- DMA or task scheduling issue.

## 4. Register Evidence

Probe command:

```powershell
tools/register_probe.ps1 -Target rcc,gpio,usart
```

Failing snapshot pattern:

```text
[REG] RCC_APB1ENR 0x40023840 = 0x10220000
      USART2EN(bit17)=0
      USART3EN(bit18)=1

[REG] GPIOD_MODER 0x40020C00 = 0xA000A800
      PD5=AF, PD6=AF, PD8=AF, PD9=AF

[REG] GPIOD_AFRL 0x40020C20 = 0x07700000
      PD5=AF7 USART2_TX
      PD6=AF7 USART2_RX

[REG] USART2_CR1 0x4000440C = 0x00000000
      UE=0, TE=0, RE=0
```

The GPIO alternate-function mapping is plausible, but the USART2 peripheral clock and control register are inconsistent with an active serial output path.

## 5. AI Analysis Summary

AI can narrow the root-cause search:

- GPIO AF mapping is not the first suspect because PD5/PD6 decode as AF7.
- Baudrate cannot explain `USART2_CR1 = 0x00000000`.
- RS422 DE timing cannot create a disabled USART peripheral.
- Missing or reordered `__HAL_RCC_USART2_CLK_ENABLE()` is the most likely cause.

## 6. Engineer Confirmation

Engineer review target files:

```text
Core/Src/usart.c
Core/Src/main.c
Core/Src/stm32f4xx_hal_msp.c
```

Confirmation checklist:

- USART clock enable occurs before `HAL_UART_Init`.
- GPIO clock enable occurs before GPIO alternate-function init.
- DMA stream is initialized before UART DMA receive/transmit.
- RS422 DE GPIO defaults are safe before enabling transmit.

## 7. Minimal Fix

Expected fix pattern:

```c
__HAL_RCC_USART2_CLK_ENABLE();
__HAL_RCC_USART3_CLK_ENABLE();
```

The fix must be limited to clock/init ordering unless evidence shows a second failure.

## 8. Regression Evidence

Passing snapshot pattern:

```text
[REG] RCC_APB1ENR 0x40023840 = 0x10260000
      USART2EN(bit17)=1
      USART3EN(bit18)=1

[REG] USART2_CR1 0x4000440C = 0x0000202C
      UE=1, TE=1, RE=1

$ tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10
[RTCM] frames_total=42
[RTCM] crc_ok=42
[RTCM] crc_bad=0
[RTCM] messages=1005,1074,1084,1094,1124
[RTCM-RESULT] PASS
```

## 9. Value

Traditional path:

```text
wiring -> baudrate -> GPIO AF -> RS422 DE -> DMA -> task scheduling -> USART -> RCC
```

AI workflow path:

```text
failed parser gate -> register probe -> RCC/GPIO/USART decode -> engineer confirmation -> minimal fix -> parser regression
```

The main gain is not that AI guesses the bug. The gain is that the workflow collects the right evidence early and forces the fix to be confirmed by both registers and regression logs.
