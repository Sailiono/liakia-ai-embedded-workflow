# Case A — BMP280 Data Quality Failure

This is the recommended first known-bad exercise. It uses the same STM32F103C8T6 + BMP280 hardware as the base starter lab.

Do not open [ANSWER.md](ANSWER.md) until you have run the broken app and generated evidence.

## Files In This Pack

```text
case-a-bmp280-calibration/
  app-layer/src/liakia_lab_app.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

Import this file into your CubeMX-generated project:

```text
app-layer/src/liakia_lab_app.c -> Core/Src/liakia_lab_app.c
```

Keep the normal headers and port file from the starter lab:

```text
app-layer/include/liakia_lab_app.h
app-layer/include/liakia_lab_platform.h
app-layer/port-template/liakia_lab_port_stm32f103.c
```

## Before You Start

Confirm the normal base application already passes:

```text
version
diag i2c
sensor id
sensor read
telemetry once
```

The base app should show `SENSOR_ID ... result=PASS` and `DATA_QUALITY result=PASS`.

## Practice Steps

1. Back up your working `Core/Src/liakia_lab_app.c`.
2. Replace it with the file from this case folder.
3. Rebuild and flash.
4. Open the USART1 shell.
5. Run:

```text
version
diag i2c
sensor id
sensor read
telemetry once
```

Record which lines still pass and which line first becomes suspicious.

## Automated Expected-Failure Run

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-a `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

The run should produce an evidence package even though this case is expected to fail.

## AI Diagnosis Task

Generate the AI packet:

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-a
```

Ask AI:

```text
Use only this evidence. Do not assume the sensor is broken unless the logs prove it.
Explain why chip ID and raw bytes can pass while the data-quality gate fails.
Suggest the smallest code area to inspect first.
```

After your own diagnosis attempt, read [ANSWER.md](ANSWER.md).
