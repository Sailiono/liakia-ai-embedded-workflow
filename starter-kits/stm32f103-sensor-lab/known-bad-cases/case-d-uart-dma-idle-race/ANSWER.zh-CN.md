# Case D 答案 — UART DMA/IDLE Stream 失败

## 预期现象

低频 frame 可能 PASS，但 burst 或更高频率下会偶发失败：

```text
frames_total 增加
crc_ok 大多增加
crc_bad 在 burst load 下出现
部分 frame length 比预期短
bad frame 集中在 IDLE boundary 附近
```

## 根因

导入的 DMA/IDLE 片段在 DMA buffer 停止并复制到稳定 frame buffer 之前，就先发布了 `frame_ready` 和 `frame_len`。

高风险顺序是：

```c
uint16_t len = sizeof(rx_dma_buf) - __HAL_DMA_GET_COUNTER(hdma);
frame_len = len;
frame_ready = 1;
__HAL_UART_CLEAR_IDLEFLAG(huart);
HAL_UART_DMAStop(huart);
memcpy(frame_buf, rx_dma_buf, len);
```

consumer 可能在 producer 仍然修改 buffer 状态时看到 `frame_ready`。低流量下可能看起来正常，高流量或 burst 下就会表现为截断 frame 或 CRC 失败。

## 最小修复

先冻结 producer 状态，把 bytes 复制到稳定 buffer，最后再发布 ready flag：

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

如果 consumer 和 IRQ 共享状态，要用 critical section 或明确的 single-producer/single-consumer 交接规则保护 `frame_ready` / `frame_len`。

## 回归验证

同时跑低频和 burst 测试。只有在之前会失败的高频 case 下 `crc_bad` 仍然为 0，修复才可信。
