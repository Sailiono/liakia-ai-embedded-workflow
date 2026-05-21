# Case B — BMP280 数据质量失败

这是第一推荐的 known-bad 练习。它使用基础 Starter Lab 的 STM32F103C8T6 + BMP280 硬件。

在你运行故障代码并生成 evidence 之前，不要打开 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。

## 文件内容

```text
case-b-bmp280-calibration/
  app-layer/src/liakia_lab_app.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

把这个文件导入你自己用 CubeMX 生成的工程：

```text
app-layer/src/liakia_lab_app.c -> Core/Src/liakia_lab_app.c
```

正常头文件和 port 文件仍然使用 Starter Lab 的基础版本：

```text
app-layer/include/liakia_lab_app.h
app-layer/include/liakia_lab_platform.h
app-layer/port-template/liakia_lab_port_stm32f103.c
```

## 开始前

先确认正常基础 app 已经通过：

```text
version
diag i2c
sensor id
sensor read
telemetry once
```

基础 app 应该能看到 `SENSOR_ID ... result=PASS` 和 `DATA_QUALITY result=PASS`。

## 练习步骤

1. 备份当前可工作的 `Core/Src/liakia_lab_app.c`；
2. 用本 case 文件夹中的 `liakia_lab_app.c` 替换它；
3. 重新编译并烧录；
4. 打开 USART1 shell；
5. 运行：

```text
version
diag i2c
sensor id
sensor read
telemetry once
```

记录哪些输出仍然 PASS，以及第一条可疑输出在哪里出现。

## 自动化预期失败运行

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

这个 case 预期会失败，但 runner 仍然必须生成 evidence package。

## AI 诊断任务

生成 AI 诊断材料：

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-b
```

向 AI 提问：

```text
只能基于这些 evidence，不要在日志没有证明前假设传感器坏了。
解释为什么 chip ID 和 raw bytes 可以 PASS，但 data-quality gate 会 FAIL。
建议优先检查哪一小块代码。
```

完成自己的诊断后，再阅读 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。
