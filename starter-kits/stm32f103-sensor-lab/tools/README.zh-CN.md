# Starter-F103 Tools

## run_starter_f103.ps1

完整运行 Starter-F103 baseline：

```powershell
.\run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build/Debug/app.elf `
  -ComPort COM4 `
  -Case case-b
```

它会执行：

```text
build
flash
shell
i2c_scan
sensor_id
data_quality
telemetry_crc
reset_recovery
register_probe
evidence manifest
```

`-Elf` 是真实烧录 gate 的必要输入。如果暂时不想烧录，必须显式传 `-SkipFlash`；否则缺少 `-Elf` 会被记录为失败。

如果是在复现 known-bad，可以使用：

```powershell
.\run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -SkipBuild `
  -Elf Debug\app.elf `
  -ComPort COM4 `
  -Case case-b `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

这样 manifest 会标记为 `EXPECTED_FAIL`，适合教学和复盘。

## diagnose_starter_f103.ps1

读取 evidence package，生成 AI prompt 和 triage 摘要：

```powershell
.\diagnose_starter_f103.ps1 `
  -EvidenceDir C:\path\to\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-b
```

输出：

```text
ai_prompt.md
failure_triage.md
```

脚本不会联网，也不会调用在线 AI。

## register_probe_f103.ps1

通过 STM32CubeProgrammer 只读关键寄存器：

```powershell
.\register_probe_f103.ps1 `
  -Target rcc,gpio,usart,i2c,flash,fault `
  -OutputJson evidence-out/register_probe_f103_summary.json
```

支持 target：

```text
fault
rcc
gpio
usart
i2c
flash
all
```

该脚本只执行 `-r32` 读寄存器，不写寄存器。
