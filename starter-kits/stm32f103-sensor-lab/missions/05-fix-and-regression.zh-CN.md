# Mission 05：修复与回归

这个任务把故障排查闭环收口：修复不是终点，回归证据才是终点。

## 修复原则

修复必须满足：

- 修改范围最小；
- 能解释为什么改；
- 和 evidence 中的失败现象对应；
- 重新运行同一组 gate；
- 生成新的 evidence package。

## Case B 修复示例

如果 AI 和人工 review 确认问题是 BMP280 calibration little-endian 拼接错误，修复点应该集中在应用层：

```c
static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

不应顺手重构整个驱动，不应改 IOC，不应调整时钟树。

## 回归命令

可以手工执行：

```text
version
diag i2c
sensor id
sensor read
telemetry once
reset
version
sensor id
```

也可以使用当前自动化脚本封装为：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -Elf Debug\app.elf `
  -ComPort COMx `
  -Case case-b
```

## PASS 标准

```text
build PASS
flash PASS
shell PASS
i2c scan PASS
sensor id PASS
data quality PASS
telemetry CRC PASS
reset recovery PASS
manifest GENERATED
```

## Handoff 摘要

修复完成后，应输出一段简短 handoff：

```text
Issue:
  BMP280 chip id passed but compensated temperature was invalid.

Evidence:
  Raw calibration bytes and raw ADC values were readable.
  Failure was isolated to application-layer compensation.

Fix:
  Corrected signed 16-bit little-endian decoding for calibration values.

Regression:
  sensor id PASS
  data quality PASS
  telemetry CRC PASS
  reset recovery PASS
```
