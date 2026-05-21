# Starter-F103 快速上手

这是一条从空工程到第一次故障复盘的完整路径。目标不是直接给你一个可烧录成品，而是让你亲手完成：

```text
焊线 -> CubeMX IOC -> HAL 工程 -> Liakia 应用层 -> 编译 -> 烧录
-> 自动化 gate -> known-bad FAIL -> AI 诊断 prompt -> 修复 -> 回归 PASS
```

## 0. 你会得到什么

完成后，你应该能生成一个 evidence package，里面包含：

- build / flash / shell / I2C / sensor / telemetry / reset / register probe 的结果；
- `00_manifest.json`；
- `test_summary.md`；
- 每个 gate 的日志；
- 可直接交给 AI 分析的 `ai_prompt.md`。

第一版推荐复现 **Case B：BMP280 calibration endian bug**。它不是地址写错，而是：

```text
I2C 能通
chip id 正确
raw calibration bytes 能读
但补偿后的温度不可信
```

## 1. 硬件

推荐硬件：

| 物料 | 用途 |
|---|---|
| STM32F103C8T6 Blue Pill 类开发板 | 目标板 |
| ST-LINK/V2 或兼容调试器 | SWD 烧录、只读寄存器 probe |
| USB-TTL 3.3V 串口模块 | USART1 Shell |
| BMP280 I2C 模块 | 传感器 gate |
| 4.7k 上拉电阻 x2 | 如果 BMP280 模块没有自带 I2C 上拉 |
| 杜邦线 | SWD / UART / I2C / GND |

详细 BOM 见 [bom.zh-CN.md](bom.zh-CN.md)。

## 2. 接线

SWD：

```text
ST-LINK 3.3V  -> Blue Pill 3V3
ST-LINK GND   -> Blue Pill GND
ST-LINK SWDIO -> PA13
ST-LINK SWCLK -> PA14
ST-LINK NRST  -> NRST
```

UART Shell：

```text
USB-TTL RXD -> PA9  / USART1_TX
USB-TTL TXD -> PA10 / USART1_RX
USB-TTL GND -> GND
```

BMP280：

```text
BMP280 VCC -> 3V3
BMP280 GND -> GND
BMP280 SCL -> PB6 / I2C1_SCL
BMP280 SDA -> PB7 / I2C1_SDA
```

完整接线说明见 [wiring.zh-CN.md](wiring.zh-CN.md)。

## 3. CubeMX / IOC

新建工程：

```text
MCU: STM32F103C8Tx
```

必选配置：

| 模块 | 配置 |
|---|---|
| SYS | Debug = Serial Wire |
| RCC | HSE 8 MHz 或 HSI，先以稳定为准 |
| USART1 | PA9/PA10, 115200, 8N1 |
| I2C1 | PB6/PB7, 100 kHz, 7-bit |
| GPIO | PC13 Output |

第一版不要启用 FreeRTOS、USB CDC、UART DMA 或 I2C 400 kHz。详细检查点见 [cubemx-ioc-guide.zh-CN.md](cubemx-ioc-guide.zh-CN.md)。

生成代码后，确认工程能空编译、能通过 ST-LINK 烧录。

## 4. 接入 Liakia 应用层

把这些文件复制进你生成的 CubeMX 工程：

```text
starter-kits/stm32f103-sensor-lab/app-layer/include/liakia_lab_app.h
starter-kits/stm32f103-sensor-lab/app-layer/include/liakia_lab_platform.h
starter-kits/stm32f103-sensor-lab/app-layer/src/liakia_lab_app.c
starter-kits/stm32f103-sensor-lab/app-layer/port-template/liakia_lab_port_stm32f103.c
```

推荐放到：

```text
Core/Inc/liakia_lab_app.h
Core/Inc/liakia_lab_platform.h
Core/Src/liakia_lab_app.c
Core/Src/liakia_lab_port_stm32f103.c
```

如果你的 CubeMX 工程文件名或 HAL handle 不同，调整 `liakia_lab_port_stm32f103.c` 里的 `huart1`、`hi2c1`、`GPIOC/GPIO_PIN_13`。

在 `main.c` include 区域加入：

```c
#include "liakia_lab_app.h"
```

初始化外设后调用：

```c
LiakiaLab_Init();
```

主循环中调用：

```c
while (1)
{
  LiakiaLab_Tick();
}
```

USART1 单字节中断接收示例：

```c
uint8_t uart_rx_byte;

HAL_UART_Receive_IT(&huart1, &uart_rx_byte, 1);

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
  if (huart->Instance == USART1) {
    LiakiaLab_OnUartRx(uart_rx_byte);
    HAL_UART_Receive_IT(&huart1, &uart_rx_byte, 1);
  }
}
```

更详细说明见 [app-layer/README.zh-CN.md](app-layer/README.zh-CN.md)。

## 5. 先跑正常应用层

编译并确认串口能看到：

```text
Liakia Starter-F103 ready
```

手工发送：

```text
version
diag i2c
sensor id
sensor read
telemetry once
```

正常基础 app 的关键输出应该包含：

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
RAW_CALIB result=PASS ...
DECODED dig_T1=... dig_T2=... dig_T3=...
RAW_TEMP adc=... result=PASS
COMP_TEMP x100=... result=PASS
DATA_QUALITY result=PASS
TELEMETRY ... crc=... result=PASS
```

如果你的 BMP280 地址是 `0x77`，基础 app 会自动尝试 `0x76` 和 `0x77`。

## 6. 跑 baseline runner

如果你的工程有 CMake preset：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build\Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

如果你用 STM32CubeIDE 编译，可以先在 IDE 里 build，然后让 runner 跳过 build：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

如果你暂时不想烧录，必须显式写 `-SkipFlash`。没有 `-Elf` 时 runner 会失败，避免误以为已经测试了新固件。

## 7. 制造 Case B known-bad

最快的教学方式是按 Case B 练习卡片操作：

```text
known-bad-cases/case-b-bmp280-calibration.zh-CN.md
```

该页面会给出应用层位置和最小注入方式。第一遍请把 known-bad 改动当成黑盒练习：先应用、编译、烧录、观察 evidence，再去看答案解析。

重新编译、烧录，然后用预期失败模式运行：

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

此时结果应是 `EXPECTED_FAIL`，而不是普通 PASS。重点是 evidence package 必须生成。

Gate 定义见 [test-gates.zh-CN.md](test-gates.zh-CN.md)。

## 8. 生成 AI 诊断材料

找到上一步输出目录，例如：

```text
C:\work\f103-liakia\evidence-out\starter-f103-20260521-120000
```

运行：

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-20260521-120000 `
  -Case case-b
```

输出：

```text
ai_prompt.md
failure_triage.md
```

把 `ai_prompt.md` 交给 AI，要求它只能基于证据分析，不允许直接猜硬件坏。

AI 诊断约束见 [diagnosis-playbook.zh-CN.md](diagnosis-playbook.zh-CN.md)。

## 9. 修复并回归

AI 诊断和人工 review 后，只做 evidence 指向的最小修复。如果卡住，再去看 [case-b-bmp280-calibration.zh-CN.md](known-bad-cases/case-b-bmp280-calibration.zh-CN.md) 的答案解析。

重新编译、烧录、运行 baseline：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

通过标准：

```text
build PASS
flash PASS
shell PASS
i2c_scan PASS
sensor_id PASS
data_quality PASS
telemetry_crc PASS
reset_recovery PASS 或有明确日志说明
register_probe PASS 或有明确跳过原因
manifest generated
```

证据包格式见 [evidence-template/README.zh-CN.md](evidence-template/README.zh-CN.md)。

## 10. 常见卡点

| 现象 | 优先检查 |
|---|---|
| ST-LINK 连接失败 | GND、SWDIO/SWCLK、BOOT0、SWD 频率、NRST |
| 串口无输出 | TX/RX 是否交叉、COM 口、115200 8N1、是否启动接收中断 |
| `diag i2c` 找不到 BMP280 | 供电、SDA/SCL、上拉、电压、模块地址 |
| `sensor id` PASS 但 `sensor read` FAIL | calibration endian、signed/unsigned、补偿公式 |
| reset 后失败 | reset recovery、I2C bus recovery、RCC_CSR reset reason |

排查细节见 [troubleshooting.zh-CN.md](troubleshooting.zh-CN.md)。
