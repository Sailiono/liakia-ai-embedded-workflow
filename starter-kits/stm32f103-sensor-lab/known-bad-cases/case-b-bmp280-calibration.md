# Case B: BMP280 Calibration Sign / Endian Bug

## 1. Why This Case Is First Priority

It does not require complex hardware, DMA, or Flash writes. With only a BMP280 connected, the user can reproduce a common embedded issue:

```text
I2C works
chip id is correct
raw bytes are readable
but compensated temperature is not credible
```

The first pass only implements the temperature compensation gate. Pressure compensation is reserved for later expansion. This case demonstrates Liakia's core point: **a working protocol does not guarantee trustworthy data**.

## 2. Known-Bad Code Point

Reference known-bad file:

```text
app-layer/known-bad/case_b_bmp280_calibration/liakia_bmp280_case_b.c
```

Intentional bug:

```c
static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}
```

BMP280 calibration bytes are little-endian. If signed 16-bit values such as `dig_T2` / `dig_T3` are assembled in the wrong byte order, chip ID and raw I2C reads can still PASS while the compensated result moves outside the physical range.

## 3. Expected Failure Shape

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
raw_calib_read result=PASS
raw_temp range=normal
temperature_x100 out_of_range
DATA_QUALITY result=FAIL reason=compensated_temperature_invalid
```

## 4. Evidence To Collect

```text
chip id
raw calibration bytes 0x88..0x8D
decoded dig_T1 / dig_T2 / dig_T3
raw temperature adc
compensated temperature_x100
expected physical range
```

Recommended data-quality gate:

```text
temperature_x100 must be between -4000 and 8500
raw adc must not be 0x00000 or 0xFFFFF
chip id must equal 0x58
```

## 5. Expected AI Diagnosis

The AI should first rule out:

- wrong I2C address;
- completely unresponsive sensor;
- USART shell issue;
- SWD flash issue.

Then focus on:

- calibration endian;
- signed / unsigned conversion;
- integer width;
- BMP280 compensation formula.

## 6. Fix

Fix point:

```c
static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

Regression:

```text
sensor id PASS
raw calibration read PASS
temperature range PASS
telemetry CRC PASS
```

## 7. Demonstration Value

This case is persuasive for engineers because it is not a wiring failure. Low-level reads appear correct, but the calculated data is wrong. Manual debugging often bounces between hardware, bus, sensor, and algorithm suspicion; Liakia separates evidence layers and narrows the path.
