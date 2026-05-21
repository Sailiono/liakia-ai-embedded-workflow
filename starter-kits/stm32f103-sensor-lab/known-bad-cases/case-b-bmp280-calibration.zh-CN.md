# Case B：BMP280 Calibration Sign / Endian Bug

## 1. 为什么这个 case 是第一优先级

它不依赖复杂硬件，也不依赖 DMA 或 Flash 写入。用户只要接好 BMP280，就能遇到一个真实工程常见问题：

```text
I2C 能通
chip id 正确
raw bytes 能读
但补偿后的温度/气压不可信
```

这能展示 Liakia 的核心观点：**协议能通不等于数据可信**。

## 2. Known-bad 代码点

示例 known-bad 文件：

```text
app-layer/known-bad/case_b_bmp280_calibration/liakia_bmp280_case_b.c
```

故意留下的问题：

```c
static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}
```

BMP280 calibration bytes 是 little-endian。`dig_T2` / `dig_T3` 这种 signed 16-bit 参数如果拼接顺序错误，chip id 和 I2C 读取都会 PASS，但补偿结果会偏离物理范围。

## 3. 预期失败形态

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
raw_calib_read result=PASS
raw_temp range=normal
temperature_x100 out_of_range
DATA_QUALITY result=FAIL reason=compensated_temperature_invalid
```

## 4. 应收集证据

```text
chip id
raw calibration bytes 0x88..0x8D
decoded dig_T1 / dig_T2 / dig_T3
raw temperature adc
compensated temperature_x100
expected physical range
```

推荐 data-quality gate：

```text
temperature_x100 must be between -4000 and 8500
raw adc must not be 0x00000 or 0xFFFFF
chip id must equal 0x58
```

## 5. AI 诊断期望

AI 应该先排除：

- I2C 地址错误；
- 传感器完全无响应；
- USART shell 问题；
- SWD 烧录问题。

然后聚焦：

- calibration endian；
- signed / unsigned；
- integer width；
- BMP280 compensation formula。

## 6. 修复

修复点：

```c
static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

回归标准：

```text
sensor id PASS
raw calibration read PASS
temperature range PASS
telemetry CRC PASS
```

## 7. 展示价值

这个 case 对工程师有说服力，因为它不是“不会接线”，而是“底层读数都对，但算法数据不可信”。这类问题人工排查时常会在硬件、总线、传感器、算法之间来回摇摆；Liakia 的价值是把证据分层，让定位路径收敛。
