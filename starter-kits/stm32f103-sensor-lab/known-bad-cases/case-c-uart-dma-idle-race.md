# Case C: UART DMA + IDLE Frame Race

## Practice Card

This is an advanced case. It requires a DMA/IDLE receive path and is not part of the beginner first run.

Application area:

```text
UART receive path
DMA/IDLE frame boundary
telemetry stream parser
```

Exercise setup:

1. Extend the IOC with UART DMA receive and IDLE interrupt.
2. Add a high-rate telemetry stream.
3. Run a low-rate gate and confirm it passes.
4. Run a high-rate gate and capture frame statistics.
5. Give the statistics and receive-path code to AI.

Observe:

```text
frames_total
crc_ok
crc_bad
bad frame lengths
where bad frames are truncated
idle interrupt count
DMA remaining count snapshots
```

## Stop Here For The Exercise

Everything below this line is the answer key.

## Answer Key

Typical symptom:

```text
shell command PASS
telemetry once PASS
telemetry stream 1 Hz PASS
telemetry stream 20 Hz occasionally CRC BAD
bad frame length often -1 byte
```

Likely root cause family:

- USART IDLE flag clear sequence is wrong;
- DMA NDTR snapshot timing is unstable;
- ring buffer write index is updated before data is visible;
- frame delimiter races with DMA half-transfer event;
- final byte is overwritten during high-rate continuous frames.

Fix direction:

- clear SR/DR in the right order in the IDLE ISR;
- make NDTR reading race-safe;
- update ring buffer index only after data is visible;
- gate frame parsing with both length and CRC;
- add high-rate stress testing.

Regression:

```text
telemetry 1 Hz: crc_bad = 0
telemetry 20 Hz, 60 seconds: crc_bad = 0
bad_frame_lengths = []
manifest records stress duration and frame count
```
