# Starter-F103 Tools

## `run_starter_f103.ps1`

Run the full Starter-F103 baseline:

```powershell
.\run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build/Debug/app.elf `
  -ComPort COM4 `
  -Case case-a
```

It executes:

```text
build
flash
shell
i2c_scan
sensor_id
data_quality
telemetry_crc
reset_recovery
register_probe
evidence manifest
```

`-Elf` is required for a real flash gate. If you do not want to flash, pass `-SkipFlash` explicitly; otherwise a missing `-Elf` is recorded as a failure.

Expected-failure mode for known-bad training:

```powershell
.\run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -SkipBuild `
  -Elf Debug\app.elf `
  -ComPort COM4 `
  -Case case-a `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

The manifest is marked `EXPECTED_FAIL`, which is useful for teaching and replay.

## `diagnose_starter_f103.ps1`

Read an evidence package and generate an AI prompt plus a triage summary:

```powershell
.\diagnose_starter_f103.ps1 `
  -EvidenceDir C:\path\to\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-a
```

Outputs:

```text
ai_prompt.md
failure_triage.md
```

This script does not call an online AI service.

## `register_probe_f103.ps1`

Read key registers through STM32CubeProgrammer:

```powershell
.\register_probe_f103.ps1 `
  -Target rcc,gpio,usart,i2c,flash,fault `
  -OutputJson evidence-out/register_probe_f103_summary.json
```

Supported targets:

```text
fault
rcc
gpio
usart
i2c
flash
all
```

The script only issues `-r32` read operations. It does not write registers.
