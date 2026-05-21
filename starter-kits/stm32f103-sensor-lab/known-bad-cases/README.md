# Known-Bad Case Guide

This page is written in two parts.

Read **Practice Mode** first if you want to run the lab as an exercise. It tells you where the case files are, what to build, what to observe, and what evidence to give to AI. It does not explain the root cause upfront.

Read **Answer Key** only after you have collected evidence and tried the diagnosis path.

## Practice Mode

The known-bad cases are application-layer exercises. They do not replace your CubeMX-generated IOC or HAL project. The intended workflow is:

```text
generate your own F103 HAL project
copy the Liakia app layer
inject or switch to one known-bad application case
build and flash
run the same gates
collect evidence
ask AI to diagnose from evidence
apply a minimal fix
rerun regression
```

### Case B: BMP280 Data Quality Failure

Use this case first.

Application references:

```text
app-layer/src/liakia_lab_app.c
app-layer/known-bad/case_b_bmp280_calibration/
```

Fast injection path:

1. Start from the working base app.
2. Temporarily modify the small signed 16-bit decode helper as described in [case-b-bmp280-calibration.md](case-b-bmp280-calibration.md).
3. Build and flash.
4. Run:

```powershell
tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -SkipBuild `
  -Elf Debug\app.elf `
  -ComPort COM4 `
  -Case case-b `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

Do not read the answer first. Observe:

```text
sensor id
sensor read
telemetry once
data_quality gate
```

Then run:

```powershell
tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\path\to\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-b
```

Give `ai_prompt.md` to AI and ask it to explain the failure using only the evidence.

### Case A: Reset-Related I2C Failure

This is a second-stage hardware-state case.

Application area:

```text
platform I2C recovery path
reset recovery gate
register_probe_f103.ps1
```

How to run it as an exercise:

1. Start from a working BMP280 bringup.
2. Add a deliberately incomplete reset-recovery path in the platform layer.
3. Build and flash.
4. Compare cold boot and software reset behavior.
5. Collect serial logs and register probe output.

Observe:

```text
diag i2c before reset
sensor id before reset
diag i2c after reset
sensor id after reset
GPIOB_IDR / I2C1_SR1 / I2C1_SR2
```

### Case C: UART DMA + IDLE Race

This case is for an advanced follow-up lab because it requires a DMA/IDLE receive path.

Application area:

```text
UART receive path
DMA/IDLE frame boundary
telemetry stream parser
```

How to run it as an exercise:

1. Extend the IOC with UART DMA receive and IDLE interrupt.
2. Add high-rate telemetry capture.
3. Run low-rate and high-rate telemetry gates.
4. Compare CRC and frame length statistics.

Observe:

```text
frames_total
crc_ok
crc_bad
bad frame length
where the bad frame is truncated
```

### Case D: Flash Persistence Regression

This case is for persistence and reset-state validation.

Application area:

```text
config record layout
Flash page erase/write path
post-reset config load path
```

How to run it as an exercise:

1. Add config get/set/save commands.
2. Save a value.
3. Verify immediate readback.
4. Software reset.
5. Verify post-reset readback.
6. Dump the raw config record if the gate fails.

Observe:

```text
pre-reset config readback
post-reset config readback
raw Flash record
CRC result
record version and length
```

## Answer Key

Do not start here if you want the exercise effect.

| Case | Main symptom | Likely root cause family | Best evidence |
|---|---|---|---|
| Case B | Chip ID and raw bytes are readable, but compensated temperature is not credible | Calibration endian, signed/unsigned handling, or integer width | raw calibration bytes, decoded coefficients, raw ADC, compensated value |
| Case A | Cold boot may pass, software reset may fail | I2C bus recovery or reset-state handling | reset reason, SDA/SCL state, I2C status registers, before/after reset logs |
| Case C | Low-rate telemetry passes, high-rate stream occasionally reports CRC BAD | DMA/IDLE frame boundary race or ring-buffer update order | frame lengths, CRC clusters, DMA NDTR, USART status |
| Case D | Immediate config readback passes, post-reset config readback fails | Flash alignment, erase boundary, struct layout, CRC coverage, or versioning | raw Flash record, pre/post reset config logs, CRC fields |

## Recommended Order

| Priority | Case | Why |
|---|---|---|
| P0 | [Case B](case-b-bmp280-calibration.md) | Requires only BMP280 and application code; easiest to reproduce across user environments |
| P1 | [Case D](case-d-flash-persistence-alignment.md) | Shows reset recovery and evidence value |
| P2 | [Case A](case-a-i2c-bus-stuck-reset.md) | Strong hardware-state story, but implementation needs care |
| P3 | [Case C](case-c-uart-dma-idle-race.md) | Highest technical depth; best for a second-stage lab |
