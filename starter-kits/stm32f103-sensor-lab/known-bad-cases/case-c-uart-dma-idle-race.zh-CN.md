# Case C：UART DMA + IDLE Frame Race

## 练习卡片

这是高级 case，需要 DMA/IDLE 接收路径，不属于新手第一轮必做内容。

应用层关注位置：

```text
UART receive path
DMA/IDLE frame boundary
telemetry stream parser
```

练习步骤：

1. 在 IOC 中扩展 UART DMA receive 和 IDLE interrupt；
2. 加入高频 telemetry stream；
3. 先运行低频 gate 并确认 PASS；
4. 再运行高频 gate，采集 frame statistics；
5. 把统计结果和接收路径代码交给 AI。

观察：

```text
frames_total
crc_ok
crc_bad
bad frame lengths
where bad frames are truncated
idle interrupt count
DMA remaining count snapshots
```

## 练习到这里先停止

下面是答案解析。

## 答案解析

典型现象：

```text
shell command PASS
telemetry once PASS
telemetry stream 1 Hz PASS
telemetry stream 20 Hz occasionally CRC BAD
bad frame length often -1 byte
```

常见根因方向：

- USART IDLE 标志清除顺序错误；
- DMA NDTR 快照时机不稳定；
- ring buffer write index 先更新，数据后可见；
- frame delimiter 和 DMA half-transfer event 竞争；
- 高频连续帧中最后一个字节被覆盖。

修复方向：

- 在 IDLE ISR 中按正确顺序清 SR/DR；
- 让 NDTR 读取避开竞争；
- 数据可见后再更新 ring buffer index；
- frame parser 同时使用 length 和 CRC gate；
- 增加高频压力测试。

回归标准：

```text
telemetry 1 Hz: crc_bad = 0
telemetry 20 Hz, 60 seconds: crc_bad = 0
bad_frame_lengths = []
manifest records stress duration and frame count
```
