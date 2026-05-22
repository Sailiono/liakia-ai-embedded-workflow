# AI Diagnosis Example

## Observations

- I2C scan finds one device at `0x76`.
- BMP280 chip id returns `0x58`, so the device identity is valid.
- Raw calibration bytes are readable.
- Raw temperature ADC is non-zero and plausible.
- Compensated temperature is outside physical range.

## Ruled Out

- ST-LINK / flash path: build and flash passed.
- UART shell: command responses are readable.
- I2C bus total failure: chip id and calibration bytes are readable.
- Wrong sensor family: chip id matches BMP280.

## Hypotheses

| Rank | Hypothesis | Evidence | How to confirm |
|---|---|---|---|
| 1 | Imported application-layer decode path is inconsistent with raw bytes | decoded values look suspicious | Compare the imported code with the sensor datasheet and the base app |
| 2 | Data-quality gate is checking a later algorithm stage | raw bytes readable but final value invalid | Print each intermediate value |
| 3 | Runtime path differs from the file you intended to flash | output still matches an old build | Confirm build artifact hash and flash transcript |

## Minimal Fix

Inspect the smallest imported application-layer helper that transforms raw bytes into decoded values. Do not rewrite the full driver until the evidence points to a broader problem.

## Regression Plan

- Rebuild and flash.
- Run `sensor id`.
- Run `sensor read`.
- Run `telemetry once`.
- Confirm data quality and CRC gates pass.
