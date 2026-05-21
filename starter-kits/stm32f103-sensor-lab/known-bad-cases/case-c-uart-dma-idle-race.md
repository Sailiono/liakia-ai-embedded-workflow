# Case C: UART DMA + IDLE Frame Race

## 1. Why This Case Is Second Stage

This case is technically stronger, but harder for a beginner path. It requires DMA, USART IDLE interrupt, or an equivalent frame receive mechanism in the IOC.

It is reserved for a later stage because it represents a very common intermittent embedded issue:

```text
low-rate path works
high-rate path occasionally reports CRC BAD
logs look like random byte loss
```

## 2. Expected Symptoms

```text
shell command PASS
telemetry once PASS
telemetry stream 1 Hz PASS
telemetry stream 20 Hz occasionally CRC BAD
bad frame length often -1 byte
```

## 3. Possible Root Causes

- USART IDLE flag clear sequence is wrong;
- DMA NDTR snapshot timing is unstable;
- ring buffer write index is updated before data is visible;
- frame delimiter races with DMA half-transfer event;
- final byte is overwritten during high-rate continuous frames.

## 4. Evidence To Collect

Serial statistics:

```text
frames_total
crc_ok
crc_bad
bad_frame_lengths
bad_frame_tail_bytes
bad_frame_cluster_time
```

Registers / state:

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

## 5. Expected AI Diagnosis

The AI should not simply say "serial is unstable." A better reasoning chain:

```text
shell PASS -> basic USART config likely correct
low-rate PASS -> protocol format and CRC algorithm likely correct
high-rate intermittent bad frames -> receive boundary, DMA snapshot, or ring buffer suspicious
bad lengths clustered at frame tail -> frame-tail truncation more likely than random noise
```

## 6. Fix Direction

Common strategies:

- in the IDLE ISR, clear SR/DR before freezing DMA;
- make NDTR reading race-safe;
- update ring buffer index only after data is visible;
- gate frame parsing with both length and CRC;
- add high-rate stress testing to the runner.

## 7. PASS Criteria

```text
telemetry 1 Hz: crc_bad = 0
telemetry 20 Hz, 60 seconds: crc_bad = 0
bad_frame_lengths = []
manifest records stress duration and frame count
```

## 8. Demonstration Value

Intermittent `CRC BAD` issues are expensive to debug manually. Liakia turns them into statistics and constrains AI analysis to DMA/IDLE/ring-buffer evidence.
