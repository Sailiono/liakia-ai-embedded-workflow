# Case A: I2C Bus Stuck After Software Reset

## 1. Why This Case Matters

This is not a beginner-level wrong-address or loose-wire bug. Its signature is:

```text
cold boot may pass
software reset fails
power cycle may recover it
```

That pattern is easily misdiagnosed as a bad sensor, loose wiring, module compatibility, or randomness. It demonstrates Liakia's value: connect reset reason, GPIO state, I2C scan, and recovery action into one evidence chain.

## 2. Expected Symptoms

```text
power cycle -> sensor id PASS
software reset -> sensor id FAIL
diag i2c -> no ACK
SDA idle state -> low
```

## 3. Evidence To Collect

Serial:

```text
version
diag i2c
sensor id
reset
version
diag i2c
sensor id
```

Registers:

```text
RCC_CSR      reset reason
RCC_APB1ENR  I2C1EN
GPIOB_CRL    PB6/PB7 mode
GPIOB_IDR    SDA/SCL input state
I2C1_CR1     peripheral enable / reset bit
I2C1_SR1     busy / error flags
I2C1_SR2     bus busy state
```

Physical:

```text
SDA idle voltage
SCL idle voltage
I2C pull-up presence
whether power-cycle clears the issue
```

## 4. Expected AI Reasoning

The AI should not jump to "the sensor is broken." A defensible path is:

```text
chip id passed before -> sensor and address are not primary suspects
failure occurs after software reset -> reset recovery path is suspicious
SDA low / BUSY set -> I2C bus may be stuck
power-cycle clears -> not a permanent wiring error
```

Likely hypotheses:

- no I2C bus recovery after reset;
- GPIO mode transition leaves SDA/SCL in a bad state;
- I2C peripheral BUSY flag remains set;
- slave device is left in an incomplete transaction.

## 5. Fix Direction

Application or platform layer should implement:

```text
disable I2C peripheral
temporarily configure SCL/SDA as open-drain GPIO
toggle SCL up to 9 cycles
generate stop-like condition
restore AF open-drain
re-enable I2C peripheral
retry sensor probe
```

Regression gates:

```text
power cycle sensor id PASS
software reset sensor id PASS
diag i2c found BMP280
reset recovery PASS
```

## 6. What Not To Do

- Do not simply lower I2C speed and call it fixed.
- Do not keep changing BMP280 addresses without evidence.
- Do not skip reset recovery.
- Do not claim module damage without SDA/SCL evidence.
