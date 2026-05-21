# Mission 05: Fix And Regression

This mission closes the debug loop. The fix is not the finish line; regression evidence is.

## Fix Principles

The fix must:

- be minimal;
- explain why the change is needed;
- match the failed evidence;
- rerun the same gates;
- generate a new evidence package.

## Case B Fix Example

If AI plus human review confirms the issue is BMP280 calibration little-endian decoding, the fix belongs in the application layer:

```c
static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

Do not casually rewrite the driver, change IOC, or adjust the clock tree.

## Regression Commands

Manual route:

```text
version
diag i2c
sensor id
sensor read
telemetry once
reset
version
sensor id
```

Automated route:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -Elf Debug\app.elf `
  -ComPort COMx `
  -Case case-b
```

## PASS Criteria

```text
build PASS
flash PASS
shell PASS
i2c scan PASS
sensor id PASS
data quality PASS
telemetry CRC PASS
reset recovery PASS
manifest GENERATED
```

## Handoff Summary

After the fix, produce a short handoff:

```text
Issue:
  BMP280 chip id passed but compensated temperature was invalid.

Evidence:
  Raw calibration bytes and raw ADC values were readable.
  Failure was isolated to application-layer compensation.

Fix:
  Corrected signed 16-bit little-endian decoding for calibration values.

Regression:
  sensor id PASS
  data quality PASS
  telemetry CRC PASS
  reset recovery PASS
```
