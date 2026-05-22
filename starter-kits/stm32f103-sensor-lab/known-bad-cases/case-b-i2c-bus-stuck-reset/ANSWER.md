# Case B Answer — I2C Reset Recovery Failure

## Expected Symptom

Cold boot may still work, but software-reset recovery is unreliable. Depending on the bench state, the user may see:

```text
diag i2c PASS before reset
sensor id PASS before reset
reset
diag i2c FAIL or unstable after reset
sensor id FAIL reason=i2c_no_ack
```

Register evidence may show I2C status bits or SDA/SCL state inconsistent with a clean idle bus.

## Root Cause

The imported port file reports I2C bus recovery as successful without performing real recovery.

The recovery function only performs a short readiness check and then returns success:

```c
LiakiaStatus LiakiaPlatform_I2cBusRecover(void) {
  (void)HAL_I2C_IsDeviceReady(&hi2c1, (uint16_t)(0x76u << 1), 1, 1);
  return LIAKIA_OK;
}
```

That means the application or test gate may believe the bus was recovered even when SCL pulses, peripheral reinitialization, or error-state clearing did not happen.

## Minimal Fix

Either return `LIAKIA_ERR` until recovery is implemented, or implement a real recovery path:

1. temporarily deinit I2C;
2. drive SCL as GPIO open-drain;
3. generate recovery clocks while observing SDA;
4. generate a STOP-like transition if needed;
5. reinitialize I2C;
6. verify with `HAL_I2C_IsDeviceReady`.

## Regression

Rerun cold boot and software reset checks. The result should distinguish a real PASS from an explicit recovery failure instead of silently reporting a false recovery.
