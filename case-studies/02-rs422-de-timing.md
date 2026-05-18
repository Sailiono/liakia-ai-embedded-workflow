# Case 02 — RS422 DE Timing

## 1. Background

- Platform: STM32F407 + dual RS422 output
- Firmware path: UART4 DMA ingress -> ring buffer -> USART1/USART2 output
- Stage: RTCM forwarding validation

## 2. Symptom

- RTCM input frames are received.
- Output channel is silent or truncated.
- Logic analyzer shows short bursts but incomplete frames.
- CRC parser reports bad or missing frames.

## 3. Initial Hypotheses

- DE pin not asserted before transmit.
- DE pin released before TX complete.
- DMA complete event confused with USART transmission complete.
- Output baudrate mismatch.
- Ring buffer overrun.

## 4. Evidence To Collect

```text
GPIOx_MODER
GPIOx_ODR
USARTx_SR / ISR
USARTx_CR1
DMA stream state
RTCM parser frame count
```

Optional lab evidence:

- logic analyzer capture of TX and DE;
- timestamped serial log;
- CRC bad count before and after fix.

## 5. AI Analysis Summary

The AI checks whether DE is controlled around the real hardware transmission boundary, not only around the software buffer copy.

Key rule:

```text
DE high -> start USART TX/DMA -> wait for TC -> DE low
```

## 6. Human Confirmation

The engineer confirms the timing requirement from the RS422 transceiver and reviews whether the firmware waits for transmission complete before deasserting DE.

## 7. Fix Pattern

Typical code area:

```text
Core/Src/passthrough.c
Core/Src/usart.c
```

Fix principle:

- assert DE before TX;
- start DMA or blocking TX;
- wait for USART TC;
- deassert DE only after the final stop bit is shifted out.

## 8. Regression

```powershell
tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10
```

Expected:

```text
frames_total > 0
crc_bad = 0
```

## 9. Value

This case shows why embedded AI workflows need hardware evidence. Logs alone are not enough; timing-sensitive bugs require register and signal-level confirmation.
