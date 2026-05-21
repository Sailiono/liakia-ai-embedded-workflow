# Case A 答案 — I2C Reset Recovery 失败

## 预期现象

冷启动可能仍然能工作，但 software reset 后的恢复不可靠。根据台架状态，可能看到：

```text
diag i2c PASS before reset
sensor id PASS before reset
reset
diag i2c FAIL or unstable after reset
sensor id FAIL reason=i2c_no_ack
```

寄存器证据中可能出现 I2C 状态位、SDA/SCL 电平和干净空闲总线不一致。

## 根因

导入的 port 文件在没有真正恢复 I2C bus 的情况下，直接报告 recovery 成功。

故障函数只是做了一次很短的 device-ready 检查，然后返回成功：

```c
LiakiaStatus LiakiaPlatform_I2cBusRecover(void) {
  (void)HAL_I2C_IsDeviceReady(&hi2c1, (uint16_t)(0x76u << 1), 1, 1);
  return LIAKIA_OK;
}
```

这会让应用或测试 gate 误以为 bus 已经恢复，但实际上没有产生 SCL recovery clocks，也没有重新初始化外设或清理错误状态。

## 最小修复

如果 recovery 还没实现，就先返回 `LIAKIA_ERR`。如果要实现真实恢复，至少需要：

1. 临时 deinit I2C；
2. 把 SCL 配成 GPIO open-drain；
3. 在观察 SDA 的同时产生 recovery clocks；
4. 必要时产生 STOP-like transition；
5. 重新初始化 I2C；
6. 用 `HAL_I2C_IsDeviceReady` 验证。

## 回归验证

重新跑冷启动和 software reset 对比。修复后，系统应该能区分真实 PASS 和明确 recovery failure，而不是静默报告假成功。
