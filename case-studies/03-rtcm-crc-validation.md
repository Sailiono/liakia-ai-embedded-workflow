# Case 03 — RTCM CRC Validation

## 1. Background

- Data source: UM982 RTCM stream
- Firmware path: UART4 DMA ingress -> parser / passthrough
- Output: RS422 channel
- Validation: RTCM3 frame parser and CRC checker

## 2. Symptom

- Serial bytes are present.
- Frames are occasionally rejected.
- CRC bad count is non-zero.
- Message type coverage is incomplete.

## 3. Initial Hypotheses

- Baudrate mismatch.
- Frame boundary detection bug.
- Ring buffer overflow.
- Output truncation.
- Parser accepts noise before preamble.
- DE timing causes clipped bytes.

## 4. Automated Test

```powershell
tools/rtcm_parse.ps1 -Port COM6 -ReadSecs 10
```

Evidence to capture:

```text
frames_total
crc_ok
crc_bad
message_types
max_frame_bytes
read_seconds
```

## 5. AI Analysis Summary

The AI compares:

- input byte rate;
- expected RTCM message mix;
- CRC bad ratio;
- maximum frame length;
- timing of parser failures.

Likely failure classes:

- transport truncation when bad frames cluster at output boundary;
- parser issue when bad frames cluster after noise or preamble mismatch;
- baudrate issue when almost all frames fail.

## 6. Human Confirmation

The engineer checks UART baudrate, DMA/ring-buffer counters, and RS422 timing evidence.

## 7. Regression Standard

```text
crc_bad = 0
required message IDs visible
no ring buffer overrun
test duration >= 10 seconds
```

## 8. Value

CRC validation turns "serial output looks alive" into measurable delivery evidence. It helps managers and engineers agree on what "working" means.
