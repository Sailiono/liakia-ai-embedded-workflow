# Handoff Report — baseline-2026-05-18

## Hardware

- MCU: STM32F407VET6
- GNSS: UM982
- Interfaces: USB CDC, USART3 debug, dual RS422

## Firmware

- RTOS: FreeRTOS
- Build system: CMake + Ninja
- Flash method: STM32CubeProgrammer CLI over SWD

## Validation

- Environment check: PASS
- Debug build: PASS
- Flash verify: PASS
- Shell test: PASS
- RTCM parse: PASS
- Register probe: PASS

## Known Limits

- This package is a public showcase baseline, not a production acceptance record.
- EMC, ESD, environmental testing, long-run reliability testing, and manufacturing test fixtures are outside this baseline.

## Next Actions

- Add real lab screenshots or logic-analyzer captures when sharing with a specific customer.
- Replace sample SHA256 placeholders with generated artifact hashes for a production handoff.
