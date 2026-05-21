# Starter-F103 测试关卡

这份文档定义 Starter-F103 Lab 每次运行时要检查什么。你可以手工执行这些命令，也可以交给 `tools/run_starter_f103.ps1` 自动执行主要检查项。

## 关卡总览

| 关卡 | 目的 | 失败后是否阻断 |
|---|---|---|
| environment | 检查工具链和串口参数 | 是 |
| build | 编译用户工程 | 是 |
| flash | ST-LINK 烧录和校验 | 是 |
| shell | 验证 USART1 Shell | 是 |
| i2c_scan | 验证 BMP280 是否可见 | 是 |
| sensor_id | 验证 chip id | 是 |
| data_quality | 验证原始字节和补偿数据是否可信 | 是 |
| telemetry_crc | 验证输出帧 CRC | 是 |
| reset_recovery | 验证 software reset 后是否恢复 | 否，第一版可选 |
| register_probe | 采集只读寄存器快照 | 否，但建议执行 |
| evidence | 生成运行清单和摘要 | 是 |

## Shell 关卡

命令：

```text
version
led on
led off
```

PASS：

```text
version 包含 Liakia Starter-F103
led on 返回 LED PASS state=on
led off 返回 LED PASS state=off
```

FAIL：

```text
串口无响应
乱码
prompt 超时
未知命令污染后续输出
```

## I2C Scan 关卡

命令：

```text
diag i2c
```

PASS：

```text
I2C_SCAN found=0x76 或 0x77
I2C_SCAN result=PASS
```

FAIL：

```text
no ACK
BUSY stuck
多个未知设备
```

## Sensor ID 关卡

命令：

```text
sensor id
```

PASS：

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
```

FAIL：

```text
id != 0x58
i2c_no_ack
timeout
```

## Data Quality 关卡

命令：

```text
sensor read
```

建议检查：

```text
raw calibration bytes readable
raw temperature adc non-zero
decoded calibration values plausible
temperature_x100 between -4000 and 8500
```

当前基础应用只启用 BMP280 温度补偿路径；气压补偿留到后续扩展。Case B 的主要失败点就是这个关卡。

## Telemetry CRC 关卡

命令：

```text
telemetry once
```

PASS：

```text
frame prefix valid
length valid
CRC valid
```

FAIL：

```text
CRC bad
frame truncated
unexpected payload length
```

## Reset Recovery 关卡

命令：

```text
version
sensor id
reset
version
sensor id
```

PASS：

```text
reset 前后 Shell 都可用
reset 前后 sensor id 都 PASS
```

FAIL：

```text
reset 后串口不恢复
reset 后 I2C no ACK
reset 后 sensor id FAIL
```

这个关卡对 Case A 和 Case D 很重要。

## Register Probe 关卡

建议读取：

```text
RCC_APB1ENR
RCC_APB2ENR
GPIOA_CRH
GPIOB_CRL
GPIOB_IDR
USART1_BRR
USART1_CR1
I2C1_CR1
I2C1_SR1
I2C1_SR2
RCC_CSR
FLASH_SR
```

第一版可以把寄存器快照做成可选项。没有 ST-LINK register dump 时，仍然可以通过串口证据完成 Case B。

## 自动化脚本契约

当前 `tools/run_starter_f103.ps1` 支持：

```powershell
tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\user\cubemx-project `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build/Debug/app.elf `
  -ComPort COM4 `
  -Case case-b `
  -OutputDir evidence-out/starter-f103
```

脚本不应假设用户工程目录结构固定。用户工程由 IOC 生成，Liakia runner 只负责调用用户提供的 build / flash / test 参数。

如果用户正在复现故障练习，可以显式声明预期失败：

```powershell
tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\user\cubemx-project `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build/Debug/app.elf `
  -ComPort COM4 `
  -Case case-b `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```
