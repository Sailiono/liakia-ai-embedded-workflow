# Case B 答案 — BMP280 数据质量失败

## 预期现象

板子仍然能和 BMP280 通信：

```text
SENSOR_ID ... id=0x58 result=PASS
RAW_CALIB result=PASS ...
RAW_TEMP adc=... result=PASS
```

但计算出的温度不可信，或者 data-quality 检查失败：

```text
COMP_TEMP x100=... result=FAIL
DATA_QUALITY result=FAIL
```

## 根因

本 case 的故障代码把 BMP280 的 signed 16-bit 校准系数按错误字节序解码。

故障 helper 是：

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}
```

BMP280 的校准寄存器是 little-endian。正确 helper 应该是：

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

## 这个 case 的价值

这不是总线不通，也不是芯片地址写错。I2C、chip ID、raw calibration read 都可能 PASS，问题只在解码和补偿之后暴露。这个场景很适合展示证据优先的 AI 诊断能力。

## 最小修复

恢复 signed 16-bit little-endian decode helper，重新编译、烧录，然后去掉 expected-failure 参数重新跑基线脚本。

预期回归：

```text
sensor_id PASS
data_quality PASS
telemetry_crc PASS
manifest generated
```
