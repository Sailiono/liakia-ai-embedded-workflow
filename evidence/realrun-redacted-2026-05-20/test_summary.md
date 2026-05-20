# Real Bench Baseline — Redacted 2026-05-20

This evidence package is a redacted public extract from a real bench run.

- Time: 2026-05-20 09:38:17 +08:00
- Source branch: `baseline/test-handoff`
- Source commit: `eb47ff1`
- Shell UART: `COM10`
- RTCM port: `COM5`
- USB CDC port: `COM12`
- Result: PASS

## Step Results

| Step | Result | Duration |
|---|---:|---:|
| Dependency check | PASS | 0.56 s |
| Build firmware | PASS | 3.04 s |
| Flash firmware | PASS | 4.00 s |
| USB CDC post-flash availability | PASS | 6.70 s |
| Functional serial test | PASS | 6.41 s |
| Input validation test | PASS | 13.99 s |
| RTCM stream test | PASS | 6.89 s |
| USB CDC reset recovery test | PASS | 20.95 s |

## Key Evidence

- Firmware build generated BIN / ELF / HEX / MAP artifacts.
- Flash and verify completed with STM32CubeProgrammer v2.22.0.
- USB CDC shell responded before and after software reset.
- RTCM parser captured 28 valid frames with 0 CRC failures.
- Expected RTCM messages were present: 1005, 1074, 1084, 1094, 1124.

## Redaction

The public extract removes local Windows user paths, ST-LINK serial number, and USB PNP serial. Customer handoff packages should keep the raw bench logs in the private delivery archive.
