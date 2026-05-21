# Case B: BMP280 Data Quality Failure

## Practice Card

This is the recommended first known-bad exercise. It requires only the F103 board, USART1 shell, and BMP280.

Application references:

```text
app-layer/src/liakia_lab_app.c
app-layer/known-bad/case_b_bmp280_calibration/
```

Exercise setup:

1. Confirm the base app can run `version`, `diag i2c`, `sensor id`, and `sensor read`.
2. Temporarily inject the known-bad helper into your copied `liakia_lab_app.c`.
3. Build and flash.
4. Run the baseline with `-ExpectedFailureGate data_quality -AllowExpectedFailure`.
5. Generate `ai_prompt.md` with `diagnose_starter_f103.ps1`.

Do not start by reading the answer. First observe:

```text
sensor id
raw calibration bytes
raw temperature adc
compensated temperature
DATA_QUALITY result
telemetry once
```

Evidence to give AI:

```text
serial logs
sensor read output
calibration decode code
temperature compensation code
00_manifest.json
test_summary.md
```

The intended question for AI is:

```text
Chip ID and raw reads appear to work, but the data-quality gate fails.
Use only the evidence to rank likely causes and propose a minimal fix.
```

## Stop Here For The Exercise

Everything below this line is the answer key. Read it after you have collected evidence and tried the AI diagnosis path.

## Answer Key

The first-pass implementation only checks BMP280 temperature compensation. Pressure compensation is intentionally left for later.

Expected failure shape:

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
RAW_CALIB result=PASS ...
RAW_TEMP adc=... result=PASS
COMP_TEMP x100=... result=FAIL
DATA_QUALITY result=FAIL
```

Likely root cause family:

- BMP280 calibration little-endian assembly;
- signed / unsigned conversion;
- intermediate integer width;
- compensation formula mismatch.

The common teaching bug is a signed 16-bit little-endian decode mistake:

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}
```

BMP280 calibration bytes are little-endian. The fix is:

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

Regression:

```text
sensor id PASS
raw calibration read PASS
temperature range PASS
data_quality PASS
telemetry CRC PASS
```

Demonstration value:

This case shows that "I2C works" does not mean "sensor data is trustworthy." Low-level reads can pass while application-layer interpretation is wrong.
