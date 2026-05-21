# Evidence Template

这个目录定义 Starter-F103 Lab 每次运行后应该留下什么证据。

第一版可以手工整理，后续由 `tools/run_starter_f103.ps1` 自动生成。

## 目录结构

```text
evidence-out/starter-f103-YYYYMMDD-HHMMSS/
├── 00_manifest.json
├── 01_environment_check.log
├── 02_build.log
├── 03_flash.log
├── 04_shell.log
├── 05_sensor_gate.log
├── 06_protocol_gate.log
├── 07_register_probe.log
├── 08_ai_diagnosis.md
├── 09_fix_diff.patch
└── test_summary.md
```

## 最小 manifest 字段

```json
{
  "project": "Liakia Starter-F103 Sensor Lab",
  "case": "case-b-bmp280-calibration",
  "timestamp_start": "YYYY-MM-DDTHH:mm:ss+08:00",
  "timestamp_end": "YYYY-MM-DDTHH:mm:ss+08:00",
  "hardware": {
    "mcu": "STM32F103C8T6",
    "board": "Blue Pill compatible",
    "sensor": "BMP280",
    "debug_probe": "ST-LINK compatible",
    "uart": "USART1 PA9/PA10",
    "i2c": "I2C1 PB6/PB7"
  },
  "results": {
    "build": "PASS",
    "flash": "PASS",
    "shell": "PASS",
    "sensor_id": "PASS",
    "data_quality": "FAIL",
    "telemetry_crc": "SKIP_AFTER_FAIL",
    "register_probe": "PASS"
  },
  "failure": {
    "failed_gate": "data_quality",
    "short_reason": "compensated temperature out of physical range"
  }
}
```

## test_summary.md 模板

```markdown
# Starter-F103 Test Summary

## Result

FAIL

## Failed Gate

data_quality

## What Passed

- Build
- Flash
- Shell version
- I2C scan
- BMP280 chip id
- Raw calibration read

## What Failed

- Compensated temperature out of physical range

## Evidence

- `04_shell.log`
- `05_sensor_gate.log`
- `07_register_probe.log`

## Next Step

Analyze calibration endian / signed decode / integer width in application layer.
```
