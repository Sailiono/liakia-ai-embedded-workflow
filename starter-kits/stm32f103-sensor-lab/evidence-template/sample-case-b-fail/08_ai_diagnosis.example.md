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
| 1 | Signed 16-bit calibration endian bug | `dig_T2` / `dig_T3` decoded suspiciously | Compare `S16()` with datasheet little-endian layout |
| 2 | Signed / unsigned mix-up | raw bytes readable but compensated value invalid | Print decoded calibration values |
| 3 | Compensation integer width issue | output invalid after formula path | Check intermediate variable types |

## Minimal Fix

Check signed little-endian decode:

```c
static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

## Regression Plan

- Rebuild and flash.
- Run `sensor id`.
- Run `sensor read`.
- Run `telemetry once`.
- Confirm data quality and CRC gates pass.
