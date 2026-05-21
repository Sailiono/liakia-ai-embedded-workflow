# Mission 03: BMP280 Bringup

This mission verifies the I2C bus, BMP280 chip ID, basic telemetry, and data-quality gate.

## Goal

```text
I2C1 can access BMP280
chip id = 0x58
telemetry once emits a frame summary with CRC
```

## Steps

1. Confirm BMP280 is connected to PB6/PB7.
2. Confirm SDA/SCL are pulled up to 3.3 V.
3. Flash the base app layer.
4. Open the serial console.
5. Send the commands below.

## Commands

```text
diag i2c
sensor id
telemetry once
```

Expected output:

```text
I2C_SCAN found=0x76
I2C_SCAN result=PASS count=1
SENSOR_ID addr=0x76 id=0x58 result=PASS
TELEMETRY LK 76 58 xx crc=xxxx result=PASS
```

If your BMP280 address is `0x77`, record that in evidence. The base app tries both `0x76` and `0x77`; this makes address differences visible before any known-bad case is imported.

## PASS Criteria

```text
i2c scan PASS
sensor id PASS
telemetry frame emitted
crc field present
```

## Failure Evidence

If it fails, collect evidence before changing code:

```text
serial command output
I2C scan result
SDA/SCL idle level
GPIOB_CRL / GPIOB_IDR summary
RCC_APB1ENR I2C1EN state
```

These become AI diagnosis inputs in Mission 04/05.
