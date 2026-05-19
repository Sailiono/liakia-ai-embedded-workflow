# Test Summary — public-showcase-baseline-2026-05-18

This baseline demonstrates a repeatable build-flash-test-diagnose-handoff loop.

## Run Identity

- Timestamp: 2026-05-18 14:33:43 +08:00
- End time: 2026-05-18 14:34:38 +08:00
- Source firmware branch: `baseline/test-handoff`
- Source firmware commit: `da023ee`
- Operator: Clark Cui
- Artifact hashes: see `firmware_sha256.txt`

## Coverage

- Build passed with CMake + Ninja.
- Firmware artifacts were generated.
- SWD flash, verify, and reset completed.
- USB CDC shell command surface responded.
- Configuration read/write path was tested.
- RTCM stream was parsed.
- CRC bad count was 0.
- SWD HotPlug register probe was available for diagnosis.

## Result

PASS

## Notes

This public sample focuses on workflow evidence format and uses sanitized local-run excerpts. Hardware-specific raw CubeProgrammer transcripts, serial-port captures, instrument screenshots, and private lab notes should be regenerated and attached for a customer acceptance package.
