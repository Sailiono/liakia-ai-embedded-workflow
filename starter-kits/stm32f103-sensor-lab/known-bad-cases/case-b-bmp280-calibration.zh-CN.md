# Case B：BMP280 Data Quality Failure

## 练习卡片

这是第一轮推荐的 known-bad 练习。它只需要 F103 板、USART1 Shell 和 BMP280。

应用层参考位置：

```text
app-layer/src/liakia_lab_app.c
app-layer/known-bad/case_b_bmp280_calibration/
```

练习步骤：

1. 先确认基础 app 可以运行 `version`、`diag i2c`、`sensor id` 和 `sensor read`；
2. 在你复制到用户工程的 `liakia_lab_app.c` 中临时注入 known-bad helper；
3. 编译并烧录；
4. 使用 `-ExpectedFailureGate data_quality -AllowExpectedFailure` 运行 baseline；
5. 用 `diagnose_starter_f103.ps1` 生成 `ai_prompt.md`。

先不要看答案。先观察：

```text
sensor id
raw calibration bytes
raw temperature adc
compensated temperature
DATA_QUALITY result
telemetry once
```

交给 AI 的 evidence：

```text
serial logs
sensor read output
calibration decode code
temperature compensation code
00_manifest.json
test_summary.md
```

给 AI 的问题应该是：

```text
Chip ID 和 raw reads 看起来正常，但 data-quality gate 失败。
请只基于 evidence 排序可能原因，并提出最小修复。
```

## 练习到这里先停止

下面是答案解析。建议你收集 evidence 并让 AI 诊断后再读。

## 答案解析

第一版只检查 BMP280 温度补偿，气压补偿留作后续扩展。

预期失败形态：

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
RAW_CALIB result=PASS ...
RAW_TEMP adc=... result=PASS
COMP_TEMP x100=... result=FAIL
DATA_QUALITY result=FAIL
```

常见根因方向：

- BMP280 calibration little-endian 拼接；
- signed / unsigned 转换；
- 中间变量宽度；
- 补偿公式不一致。

教学用 bug 通常是 signed 16-bit little-endian decode 错误：

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}
```

BMP280 calibration bytes 是 little-endian。修复为：

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

回归标准：

```text
sensor id PASS
raw calibration read PASS
temperature range PASS
data_quality PASS
telemetry CRC PASS
```

展示价值：

这个 case 说明 “I2C 能通” 不等于 “传感器数据可信”。底层读数可以 PASS，但应用层解释仍然可能错误。
