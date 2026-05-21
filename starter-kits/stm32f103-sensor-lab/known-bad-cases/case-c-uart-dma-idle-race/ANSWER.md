# Case C Answer — UART DMA/IDLE Stream Failure

## Expected Symptom

Low-rate frames may pass, while bursty or higher-rate frames intermittently fail:

```text
frames_total increases
crc_ok mostly increases
crc_bad appears under burst load
some frame lengths are shorter than expected
bad frames cluster near IDLE boundaries
```

## Root Cause

The imported DMA/IDLE fragment publishes `frame_ready` and `frame_len` before the DMA buffer has been stopped and copied into the stable frame buffer.

The risky order is:

```c
uint16_t len = sizeof(rx_dma_buf) - __HAL_DMA_GET_COUNTER(hdma);
frame_len = len;
frame_ready = 1;
__HAL_UART_CLEAR_IDLEFLAG(huart);
HAL_UART_DMAStop(huart);
memcpy(frame_buf, rx_dma_buf, len);
```

The consumer can observe `frame_ready` while the producer is still mutating the buffer state. Under light traffic this may appear to work. Under burst traffic, the race becomes visible as truncated frames or CRC failures.

## Minimal Fix

Freeze the producer state first, copy the bytes into a stable buffer, then publish the ready flag last:

```c
__HAL_UART_CLEAR_IDLEFLAG(huart);
HAL_UART_DMAStop(huart);
uint16_t len = sizeof(rx_dma_buf) - __HAL_DMA_GET_COUNTER(hdma);
if (len > sizeof(frame_buf)) {
  len = sizeof(frame_buf);
}
memcpy(frame_buf, rx_dma_buf, len);
frame_len = len;
frame_ready = 1;
HAL_UART_Receive_DMA(huart, rx_dma_buf, sizeof(rx_dma_buf));
```

If the consumer and IRQ share state, protect `frame_ready` / `frame_len` with a critical section or a single-producer/single-consumer handoff discipline.

## Regression

Run both low-rate and burst tests. The fix is only credible when `crc_bad` remains zero under the higher-rate case that previously failed.
