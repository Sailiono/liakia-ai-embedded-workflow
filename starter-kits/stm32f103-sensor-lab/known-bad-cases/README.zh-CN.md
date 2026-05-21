# Known-Bad Case 使用指南

这个页面分成两部分。

如果你想把它当成练习，请先读 **练习模式**。这里会告诉你 case 文件在哪里、如何接入、如何编译烧录、观察哪些现象、把哪些 evidence 交给 AI，但不会一开始就把根因讲透。

等你跑完、收集证据、让 AI 做过诊断之后，再读 **答案解析**。

## 练习模式

known-bad case 只作用在应用层，不替换你自己生成的 CubeMX IOC 或 HAL 工程。推荐流程是：

```text
自己生成 F103 HAL 工程
复制 Liakia app layer
注入或切换一个 known-bad 应用层 case
编译并烧录
运行同一套 gate
采集 evidence
让 AI 基于 evidence 诊断
做最小修复
重新回归
```

### Case B：BMP280 Data Quality Failure

第一轮先做这个 case。

应用层参考位置：

```text
app-layer/src/liakia_lab_app.c
app-layer/known-bad/case_b_bmp280_calibration/
```

最快注入方式：

1. 先从能正常跑的基础 app 开始；
2. 按 [case-b-bmp280-calibration.zh-CN.md](case-b-bmp280-calibration.zh-CN.md) 中的练习说明，临时修改一个很小的 signed 16-bit decode helper；
3. 编译并烧录；
4. 运行：

```powershell
tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -SkipBuild `
  -Elf Debug\app.elf `
  -ComPort COM4 `
  -Case case-b `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

先不要看答案。观察：

```text
sensor id
sensor read
telemetry once
data_quality gate
```

然后运行：

```powershell
tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\path\to\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-b
```

把 `ai_prompt.md` 交给 AI，要求它只能基于 evidence 解释失败原因。

### Case A：Reset-Related I2C Failure

这是第二阶段的硬件状态 case。

应用层关注位置：

```text
platform I2C recovery path
reset recovery gate
register_probe_f103.ps1
```

练习方式：

1. 从能正常读取 BMP280 的工程开始；
2. 在 platform 层加入一个不完整的 reset recovery 路径；
3. 编译并烧录；
4. 对比冷启动和 software reset 后的行为；
5. 收集串口日志和 register probe 输出。

观察：

```text
diag i2c before reset
sensor id before reset
diag i2c after reset
sensor id after reset
GPIOB_IDR / I2C1_SR1 / I2C1_SR2
```

### Case C：UART DMA + IDLE Race

这是高级后续 lab，需要 DMA/IDLE 接收路径。

应用层关注位置：

```text
UART receive path
DMA/IDLE frame boundary
telemetry stream parser
```

练习方式：

1. 在 IOC 中扩展 UART DMA receive 和 IDLE interrupt；
2. 加入高频 telemetry capture；
3. 分别运行低频和高频 telemetry gate；
4. 对比 CRC 和 frame length 统计。

观察：

```text
frames_total
crc_ok
crc_bad
bad frame length
where the bad frame is truncated
```

### Case D：Flash Persistence Regression

这是状态持久化和 reset 后验证 case。

应用层关注位置：

```text
config record layout
Flash page erase/write path
post-reset config load path
```

练习方式：

1. 增加 config get/set/save 命令；
2. 保存一个配置值；
3. 验证立即读回；
4. software reset；
5. 验证 reset 后读回；
6. 如果 gate 失败，dump 原始 config record。

观察：

```text
pre-reset config readback
post-reset config readback
raw Flash record
CRC result
record version and length
```

## 答案解析

如果你想保留练习效果，不要从这里开始读。

| Case | 主要现象 | 常见根因方向 | 最关键证据 |
|---|---|---|---|
| Case B | Chip ID 和 raw bytes 能读，但补偿后的温度不可信 | calibration endian、signed/unsigned、integer width | raw calibration bytes、decoded coefficients、raw ADC、compensated value |
| Case A | 冷启动可能 PASS，software reset 后可能 FAIL | I2C bus recovery 或 reset-state 处理 | reset reason、SDA/SCL state、I2C status registers、reset 前后日志 |
| Case C | 低频 telemetry PASS，高频 stream 偶发 CRC BAD | DMA/IDLE frame boundary race 或 ring-buffer 更新顺序 | frame lengths、CRC clusters、DMA NDTR、USART status |
| Case D | 立即读回 PASS，reset 后读回 FAIL | Flash alignment、erase boundary、struct layout、CRC coverage、versioning | raw Flash record、reset 前后 config log、CRC fields |

## 推荐顺序

| 优先级 | Case | 原因 |
|---|---|---|
| P0 | [Case B](case-b-bmp280-calibration.zh-CN.md) | 只依赖 BMP280 和应用层，最容易跨用户环境复现 |
| P1 | [Case D](case-d-flash-persistence-alignment.zh-CN.md) | 能展示 reset recovery 和 evidence 的价值 |
| P2 | [Case A](case-a-i2c-bus-stuck-reset.zh-CN.md) | 硬件状态故事强，但实现要谨慎 |
| P3 | [Case C](case-c-uart-dma-idle-race.zh-CN.md) | 专业度最高，适合第二阶段 |
