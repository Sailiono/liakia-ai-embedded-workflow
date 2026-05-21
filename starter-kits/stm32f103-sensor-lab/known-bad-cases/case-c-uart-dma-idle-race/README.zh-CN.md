# Case C — UART DMA/IDLE Stream 失败

这是高级 known-bad 练习，需要在 IOC 中扩展 UART DMA receive 和 IDLE interrupt。

在采集低频和高频 stream evidence 之前，不要打开 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。

## 文件内容

```text
case-c-uart-dma-idle-race/
  app-layer/src/liakia_uart_dma_idle_case_c.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

把源文件导入你的工程：

```text
app-layer/src/liakia_uart_dma_idle_case_c.c -> Core/Src/liakia_uart_dma_idle_case_c.c
```

## IOC 扩展

新增第二路 UART，或者在不影响 shell 的前提下复用 USART1。

需要启用：

```text
UART RX DMA circular 或 normal receive
UART global interrupt
IDLE line interrupt
DMA channel interrupt
```

第一遍保持简单，不要同时引入 FreeRTOS 或多个 producer。先让单一路径可观察。

## 练习步骤

1. 确认基础 shell 仍然可用；
2. 导入 `liakia_uart_dma_idle_case_c.c`；
3. 在 UART/DMA 初始化后调用 `LiakiaCaseC_Start()`；
4. 在 UART IRQ 中转调 `LiakiaCaseC_UartIrq()`；
5. 在 main loop 或测试命令里轮询 `LiakiaCaseC_TryGetFrame()`；
6. 送入低频 frame stream 并记录结果；
7. 送入更高频或 bursty stream 并记录结果。

## 需要采集的证据

采集：

```text
frames_total
crc_ok
crc_bad
frame_len distribution
first bad frame offset
DMA NDTR when IDLE fires
USART SR flags
```

如果可以，保留解析前的 raw byte capture。它通常比单纯 summary 更有诊断价值。

## AI 诊断任务

向 AI 提问：

```text
基于低频和高频 evidence。
找出 PASS stream 和 FAIL stream 的差异。
判断更像 parser logic、CRC logic、buffer lifetime，还是 DMA/IDLE ordering。
建议优先检查哪一个 callback 或 IRQ path。
```

完成诊断后再阅读 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。
