# Starter-F103 Test Gates

This document defines the Starter-F103 gates. They can be executed manually or through `tools/run_starter_f103.ps1`.

## Gate Overview

| Gate | Purpose | Blocking |
|---|---|---|
| environment | Check toolchain and serial parameters | Yes |
| build | Build the user project | Yes |
| flash | Flash and verify through ST-LINK | Yes |
| shell | Verify USART1 shell | Yes |
| i2c_scan | Verify BMP280 visibility | Yes |
| sensor_id | Verify chip ID | Yes |
| data_quality | Verify raw bytes and compensated data | Yes |
| telemetry_crc | Verify output frame CRC | Yes |
| reset_recovery | Verify recovery after software reset | No, optional in the first pass |
| register_probe | Collect read-only register evidence | No, recommended |
| evidence | Generate manifest and summary | Yes |

## Shell Gate

Commands:

```text
version
led on
led off
```

PASS:

```text
version contains Liakia Starter-F103
led on returns LED PASS state=on
led off returns LED PASS state=off
```

FAIL:

```text
no serial response
garbled output
prompt timeout
unknown command pollutes later output
```

## I2C Scan Gate

Command:

```text
diag i2c
```

PASS:

```text
I2C_SCAN found=0x76 or 0x77
I2C_SCAN result=PASS
```

FAIL:

```text
no ACK
BUSY stuck
multiple unexpected devices
```

## Sensor ID Gate

Command:

```text
sensor id
```

PASS:

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
```

FAIL:

```text
id != 0x58
i2c_no_ack
timeout
```

## Data Quality Gate

Command:

```text
sensor read
```

Recommended checks:

```text
raw calibration bytes readable
raw temperature adc non-zero
decoded calibration values plausible
temperature_x100 between -4000 and 8500
```

The base application currently enables only the BMP280 temperature compensation path. Pressure compensation is reserved for later expansion. Case A fails primarily at this gate.

## Telemetry CRC Gate

Command:

```text
telemetry once
```

PASS:

```text
frame prefix valid
length valid
CRC valid
```

FAIL:

```text
CRC bad
frame truncated
unexpected payload length
```

## Reset Recovery Gate

Commands:

```text
version
sensor id
reset
version
sensor id
```

PASS:

```text
Shell is usable before and after reset
sensor id passes before and after reset
```

FAIL:

```text
serial does not recover after reset
I2C no ACK after reset
sensor id fails after reset
```

This gate becomes more important for Case B and Case C.

## Register Probe Gate

Recommended registers:

```text
RCC_APB1ENR
RCC_APB2ENR
GPIOA_CRH
GPIOB_CRL
GPIOB_IDR
USART1_BRR
USART1_CR1
I2C1_CR1
I2C1_SR1
I2C1_SR2
RCC_CSR
FLASH_SR
```

The first lab can treat register probing as optional. Case A can still be completed with serial evidence only, but register snapshots improve handoff quality.

## Automation Contract

Current runner:

```powershell
tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\user\cubemx-project `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build/Debug/app.elf `
  -ComPort COM4 `
  -Case case-a `
  -OutputDir evidence-out/starter-f103
```

The script must not assume a fixed CubeMX project layout. The user supplies build, flash, and serial parameters.

Expected-failure mode:

```powershell
tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\user\cubemx-project `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build/Debug/app.elf `
  -ComPort COM4 `
  -Case case-a `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```
