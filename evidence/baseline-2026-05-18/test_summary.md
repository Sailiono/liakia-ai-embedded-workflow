# Test Summary — baseline-2026-05-18

This baseline demonstrates a repeatable build-flash-test-diagnose-handoff loop.

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

This public sample focuses on workflow evidence format. Hardware-specific serial port names, instrument screenshots, and private lab notes are intentionally excluded.
