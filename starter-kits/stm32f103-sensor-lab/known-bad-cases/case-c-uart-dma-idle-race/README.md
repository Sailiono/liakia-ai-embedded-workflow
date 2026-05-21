# Case C — UART DMA/IDLE Stream Failure

This is an advanced known-bad exercise. It requires an IOC extension for UART DMA receive and IDLE interrupt handling.

Do not open [ANSWER.md](ANSWER.md) before collecting low-rate and high-rate stream evidence.

## Files In This Pack

```text
case-c-uart-dma-idle-race/
  app-layer/src/liakia_uart_dma_idle_case_c.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

Import the source file into your project:

```text
app-layer/src/liakia_uart_dma_idle_case_c.c -> Core/Src/liakia_uart_dma_idle_case_c.c
```

## IOC Extension

Add a second UART or reuse USART1 only if your shell is not sharing the same receive path.

Required features:

```text
UART RX DMA circular or normal receive
UART global interrupt
IDLE line interrupt
DMA channel interrupt
```

Keep the first attempt simple. Do not add FreeRTOS or multiple producers until the single DMA/IDLE path is observable.

## Practice Steps

1. Confirm the base shell still works.
2. Import `liakia_uart_dma_idle_case_c.c`.
3. Call `LiakiaCaseC_Start()` after UART/DMA init.
4. Forward the UART IRQ to `LiakiaCaseC_UartIrq()`.
5. Poll `LiakiaCaseC_TryGetFrame()` from the main loop or a test command.
6. Feed a low-rate frame stream and record the result.
7. Feed a higher-rate or bursty stream and record the result.

## Evidence To Collect

Collect:

```text
frames_total
crc_ok
crc_bad
frame_len distribution
first bad frame offset
DMA NDTR when IDLE fires
USART SR flags
```

If possible, keep one raw byte capture before parsing. That capture is often more useful than a summary alone.

## AI Diagnosis Task

Ask AI:

```text
Use the low-rate and high-rate evidence.
Find what changes between the passing stream and the failing stream.
Explain whether the failure is more likely parser logic, CRC logic, buffer lifetime, or DMA/IDLE ordering.
Suggest the smallest callback or IRQ path to inspect.
```

Then read [ANSWER.md](ANSWER.md).
