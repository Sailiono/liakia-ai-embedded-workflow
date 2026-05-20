# Remote Hardware-In-The-Loop Baseline — Redacted 2026-05-20

This evidence package is a sanitized public extract from a remote hardware-in-the-loop run.

- Time: 2026-05-20 10:33:21 +08:00
- Collection mode: remote bench execution over SSH
- Source branch: `baseline/test-handoff`
- Source commit: `eb47ff1`
- Preset: `Debug`
- Shell UART: `COM10`
- RTCM port: `COM5`
- USB CDC port: `COM12`
- RS422 output: both
- Result: PASS

## Step Results

| Step | Result | Duration |
|---|---:|---:|
| Dependency check | PASS | 0.42 s |
| Build firmware | PASS | 0.52 s |
| Flash firmware | PASS | 3.96 s |
| USB CDC post-flash availability | PASS | 6.68 s |
| Functional serial test | PASS | 6.32 s |
| Input validation test | PASS | 12.20 s |
| RTCM stream test | PASS | 11.08 s |
| USB CDC reset recovery test | PASS | 21.11 s |

## Key Evidence

- Remote bench command executed the same baseline runner used for local hardware validation.
- Firmware build generated BIN / ELF / HEX / MAP artifacts.
- Flash and verify completed through the ST-LINK physically attached to the bench PC.
- USB CDC shell responded before and after software reset.
- RTCM parser captured 52 valid frames over 10 seconds with 0 CRC failures.
- Expected RTCM messages were present: 1005, 1074, 1084, 1094, 1124.

## Firmware Artifacts

| Artifact | Size |
|---|---:|
| `dpiny-RTK.bin` | 103,136 bytes |
| `dpiny-RTK.elf` | 1,640,828 bytes |
| `dpiny-RTK.hex` | 290,153 bytes |
| `dpiny-RTK.map` | 1,121,270 bytes |

## Redaction

The public extract removes the bench computer name, local IP address, Windows user name, private local paths, SSH key path, ST-LINK serial number, and USB PNP serial. Customer handoff packages should keep those raw details in the private delivery archive.
