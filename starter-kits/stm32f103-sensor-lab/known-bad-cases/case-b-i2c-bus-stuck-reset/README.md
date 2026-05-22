# Case B — I2C Reset Recovery Failure

This is a hardware-state exercise. It is best after the base BMP280 lab already works and after you have a reset-recovery gate or manual reset test.

Do not open [ANSWER.md](ANSWER.md) before collecting cold-boot and post-reset evidence.

## Files In This Pack

```text
case-b-i2c-bus-stuck-reset/
  app-layer/port-template/liakia_lab_port_stm32f103.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

Import this file into your CubeMX-generated project:

```text
app-layer/port-template/liakia_lab_port_stm32f103.c -> Core/Src/liakia_lab_port_stm32f103.c
```

Keep your normal `liakia_lab_app.c`.

## Practice Steps

1. Confirm the base app passes after a cold boot.
2. Back up your working `Core/Src/liakia_lab_port_stm32f103.c`.
3. Replace it with the file from this case folder.
4. Rebuild and flash.
5. Run the normal sensor commands after cold boot:

```text
diag i2c
sensor id
sensor read
```

6. Trigger a software reset from the shell:

```text
reset
```

7. After the board returns, run the same commands again.

## Evidence To Collect

Collect before/after reset logs:

```text
diag i2c
sensor id
sensor read
reset
diag i2c
sensor id
sensor read
```

If you have ST-LINK register probe enabled, capture:

```text
RCC_CSR
GPIOB_IDR
I2C1_SR1
I2C1_SR2
I2C1_CR1
```

## AI Diagnosis Task

Ask AI:

```text
Use only the before/after reset logs and register probe.
Compare cold-boot behavior with software-reset behavior.
Identify whether the failure looks like wiring, device address, or reset-state recovery.
Suggest the smallest platform-layer function to inspect.
```

Then read [ANSWER.md](ANSWER.md).
