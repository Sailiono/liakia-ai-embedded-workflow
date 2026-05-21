# Case C：UART DMA + IDLE Frame Race

## 1. 为什么这个 case 留到第二阶段

这个 case 专业度更高，但对新手入口也更难。它需要用户在 IOC 中启用 DMA、USART IDLE 中断或等价的帧接收机制。

它适合第二阶段，因为它展示的是嵌入式中非常典型的偶发问题：

```text
低频正常
高频偶发 CRC BAD
日志看起来像随机丢字节
```

## 2. 预期现象

```text
shell command PASS
telemetry once PASS
telemetry stream 1 Hz PASS
telemetry stream 20 Hz occasionally CRC BAD
bad frame length often -1 byte
```

## 3. 可能根因

- USART IDLE 标志清除顺序错误；
- DMA NDTR 快照时机不稳定；
- ring buffer write index 先更新，数据后写入；
- frame delimiter 和 DMA 半传输事件竞争；
- 高速连续帧中最后一个字节被下一轮覆盖。

## 4. 应收集证据

串口统计：

```text
frames_total
crc_ok
crc_bad
bad_frame_lengths
bad_frame_tail_bytes
bad_frame_cluster_time
```

寄存器/状态：

```text
USART1_SR
USART1_DR
USART1_BRR
DMA1_CNDTR
DMA1_CCR
rx_write_index
rx_read_index
idle_irq_count
```

## 5. AI 诊断期望

AI 不应该只说“串口不稳定”。合理路径是：

```text
shell PASS -> 基础 USART 配置大概率正确
低频 PASS -> 协议格式和 CRC 算法大概率正确
高频偶发 bad frame -> 接收边界、DMA 快照或 ring buffer 可疑
bad length clustered at frame tail -> 帧尾截断比随机噪声更可能
```

## 6. 修复方向

常见修复策略：

- 在 IDLE ISR 中先清 SR/DR，再冻结 DMA；
- 读取 NDTR 时保证不会和 DMA 写入竞争；
- ring buffer 更新顺序改为“数据可见后更新索引”；
- 对帧解析增加长度和 CRC 双 gate；
- 在测试脚本中增加高频压力测试。

## 7. 通过标准

```text
telemetry 1 Hz: crc_bad = 0
telemetry 20 Hz, 60 seconds: crc_bad = 0
bad_frame_lengths = []
manifest records stress duration and frame count
```

## 8. 展示价值

这类问题人工调试成本高，尤其是“偶发 CRC BAD”。Liakia 可以把偶发变成统计，并把 AI 分析限制在 DMA/IDLE/ring buffer 的证据上。
