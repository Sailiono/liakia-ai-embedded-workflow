# Known-Bad Fault Design

The known-bad cases in this lab are not simple "wrong address" examples. They are selected because they are common in real embedded bringup, expensive to debug manually, and suitable for evidence-driven diagnosis.

## Case A: I2C Bus Stuck After Software Reset

Symptom:

```text
BMP280 may pass after cold boot
sensor gate fails after software reset
power cycle may recover it
```

Possible root causes:

- I2C peripheral state not fully recovered after reset;
- SDA held low by the slave or MCU configuration;
- missing I2C bus recovery in the application/platform layer;
- unstable GPIO open-drain / pull-up state during init.

Evidence:

```text
I2C scan result: no ACK
GPIOB_IDR: SDA low
RCC_CSR: software reset flag set
sensor reset recovery gate: FAIL
```

Value:

This issue is often misdiagnosed as a broken sensor, loose wire, or wrong address. The Liakia route links reset reason, GPIO state, I2C scan, and recovery actions into one evidence chain.

## Case B: BMP280 Calibration Sign / Endian Bug

Symptom:

```text
chip id PASS
I2C read PASS
raw adc value looks normal
temperature output out of physical range
```

Possible root causes:

- BMP280 calibration signed / unsigned handling bug;
- little-endian assembly bug;
- insufficient intermediate integer width;
- float/integer boundary bug in compensation.

Evidence:

```text
raw calibration bytes: readable
raw adc temperature: in expected range
compensated temperature: invalid
data quality gate: FAIL
```

Value:

It proves "the bus works" does not mean "the data is trustworthy." This is closer to product debugging than simply reading chip ID.

## Case C: UART DMA + IDLE Frame Race

Symptom:

```text
shell command PASS
low-rate telemetry PASS
high-rate telemetry occasionally CRC BAD
```

Possible root causes:

- USART IDLE flag clear sequence bug;
- unstable DMA NDTR snapshot timing;
- ring buffer write index updated before data is visible;
- frame delimiter racing with DMA half-transfer event;
- final byte overwritten during high-rate continuous frames.

Evidence:

```text
raw frame length occasionally shorter by 1 byte
CRC BAD clustered at frame tail
USART SR / DMA CNDTR snapshot inconsistent
```

Value:

This is a real intermittent embedded bug class. Liakia's value is turning intermittent behavior into statistics and reproducible gates.

## Case D: Flash Config Persistence Alignment Bug

Symptom:

```text
config set then immediate readback PASS
after software reset, config is lost or fields are shifted
```

Possible root causes:

- F103 Flash half-word write granularity handled incorrectly;
- page erase boundary bug;
- struct padding not fixed;
- CRC covers inconsistent payload;
- version upgrade strategy not explicit.

Evidence:

```text
pre-reset config readback: PASS
post-reset config readback: FAIL
flash raw dump: field offset mismatch
persistence gate: FAIL
```

Value:

This is easy to miss with manual testing. It is a strong regression automation example.

## Recommended Implementation Order

| Priority | Case | Reason |
|---|---|---|
| P0 | [Case B](case-b-bmp280-calibration.md) | Requires only BMP280 and application code; easiest to reproduce across user environments |
| P1 | [Case D](case-d-flash-persistence-alignment.md) | Shows reset recovery and evidence value |
| P2 | [Case A](case-a-i2c-bus-stuck-reset.md) | Strong hardware-state story, but implementation needs care |
| P3 | [Case C](case-c-uart-dma-idle-race.md) | Highest technical depth; best for a second-stage lab |
