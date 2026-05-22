# Case A Answer — BMP280 Data Quality Failure

## Expected Symptom

The board can still communicate with the BMP280:

```text
SENSOR_ID ... id=0x58 result=PASS
RAW_CALIB result=PASS ...
RAW_TEMP adc=... result=PASS
```

But the calculated temperature becomes physically implausible or the data-quality gate fails:

```text
COMP_TEMP x100=... result=FAIL
DATA_QUALITY result=FAIL
```

## Root Cause

The intentionally broken application file decodes signed 16-bit BMP280 calibration coefficients in the wrong byte order.

The faulty helper is:

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}
```

BMP280 calibration registers are little-endian. The correct helper is:

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

## Why This Case Is Useful

This is not a dead bus or a wrong chip address. The I2C link, chip ID, and raw calibration read can all pass. The failure only appears after decoding and compensation, which is exactly where evidence-based AI diagnosis is useful.

## Minimal Fix

Restore the signed 16-bit little-endian decode helper, rebuild, flash, and rerun the baseline without expected-failure flags.

Expected regression:

```text
sensor_id PASS
data_quality PASS
telemetry_crc PASS
manifest generated
```
