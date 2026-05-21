# Case A: Reset-Related I2C Failure

## Practice Card

This is a second-stage case. Start it only after the BMP280 base path works.

Application area:

```text
platform I2C recovery path
reset recovery gate
register_probe_f103.ps1
```

Exercise setup:

1. Start from a firmware that passes `sensor id` after cold boot.
2. Add or keep an incomplete I2C reset-recovery path.
3. Build and flash.
4. Compare cold boot against software reset.
5. Collect serial logs and register snapshots.

Observe:

```text
diag i2c before reset
sensor id before reset
diag i2c after reset
sensor id after reset
SDA/SCL idle state if available
```

Evidence to give AI:

```text
before/after reset serial logs
RCC_CSR
GPIOB_IDR
I2C1_CR1
I2C1_SR1
I2C1_SR2
platform I2C recovery code
```

## Stop Here For The Exercise

Everything below this line is the answer key.

## Answer Key

Typical symptom:

```text
power cycle -> sensor id PASS
software reset -> sensor id FAIL
diag i2c -> no ACK
SDA may be low or I2C BUSY may remain set
```

Likely root cause family:

- missing I2C bus recovery after reset;
- GPIO mode transition leaves SDA/SCL in a bad state;
- I2C peripheral BUSY flag remains set;
- slave device is left in an incomplete transaction.

Fix direction:

```text
disable I2C peripheral
temporarily configure SCL/SDA as open-drain GPIO
toggle SCL up to 9 cycles
generate stop-like condition
restore AF open-drain
re-enable I2C peripheral
retry sensor probe
```

Regression:

```text
power cycle sensor id PASS
software reset sensor id PASS
diag i2c found BMP280
reset recovery PASS
```
