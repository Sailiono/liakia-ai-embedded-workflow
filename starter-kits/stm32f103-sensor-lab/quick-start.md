# Starter-F103 Quick Start

This is the complete hands-on path from an empty STM32CubeMX project to a first failure-to-fix replay.

The goal is not to provide a prebuilt firmware image. The goal is to let you perform the real loop:

```text
wiring -> CubeMX IOC -> HAL project -> Liakia application layer -> build -> flash
-> automated gates -> known-bad failure -> AI diagnosis prompt -> fix -> regression PASS
```

## 0. What You Will Produce

After the lab, you should have an evidence package containing:

- build / flash / shell / I2C / sensor / telemetry / reset / register probe results;
- `00_manifest.json`;
- `test_summary.md`;
- per-gate logs;
- an `ai_prompt.md` file ready for evidence-based AI diagnosis.

The recommended first case is **Case B: BMP280 calibration endian bug**. It is not a trivial wrong-address bug:

```text
I2C works
chip id is correct
raw calibration bytes are readable
but compensated temperature is not physically credible
```

## 1. Hardware

Recommended setup:

| Item | Purpose |
|---|---|
| STM32F103C8T6 Blue Pill compatible board | Target board |
| ST-LINK/V2 or compatible probe | SWD flash and read-only register probe |
| USB-TTL 3.3 V serial adapter | USART1 shell |
| BMP280 I2C module | Sensor gate |
| Two 4.7k pull-up resistors | Only needed if the BMP280 module has no I2C pull-ups |
| Jumper wires | SWD / UART / I2C / common ground |

## 2. Wiring

SWD:

```text
ST-LINK 3.3V  -> Blue Pill 3V3
ST-LINK GND   -> Blue Pill GND
ST-LINK SWDIO -> PA13
ST-LINK SWCLK -> PA14
ST-LINK NRST  -> NRST
```

UART shell:

```text
USB-TTL RXD -> PA9  / USART1_TX
USB-TTL TXD -> PA10 / USART1_RX
USB-TTL GND -> GND
```

BMP280:

```text
BMP280 VCC -> 3V3
BMP280 GND -> GND
BMP280 SCL -> PB6 / I2C1_SCL
BMP280 SDA -> PB7 / I2C1_SDA
```

## 3. CubeMX / IOC

Create a new project:

```text
MCU: STM32F103C8Tx
```

Required configuration:

| Module | Setting |
|---|---|
| SYS | Debug = Serial Wire |
| RCC | HSE 8 MHz or HSI; choose the stable option first |
| USART1 | PA9/PA10, 115200, 8N1 |
| I2C1 | PB6/PB7, 100 kHz, 7-bit |
| GPIO | PC13 Output |

For the first pass, do not enable FreeRTOS, USB CDC, UART DMA, or I2C 400 kHz. Keep the bringup small and observable.

After code generation, confirm the empty project builds and flashes through ST-LINK.

## 4. Add The Liakia Application Layer

Copy these files into your generated CubeMX project:

```text
starter-kits/stm32f103-sensor-lab/app-layer/include/liakia_lab_app.h
starter-kits/stm32f103-sensor-lab/app-layer/include/liakia_lab_platform.h
starter-kits/stm32f103-sensor-lab/app-layer/src/liakia_lab_app.c
starter-kits/stm32f103-sensor-lab/app-layer/port-template/liakia_lab_port_stm32f103.c
```

Recommended destination:

```text
Core/Inc/liakia_lab_app.h
Core/Inc/liakia_lab_platform.h
Core/Src/liakia_lab_app.c
Core/Src/liakia_lab_port_stm32f103.c
```

If your generated project uses different HAL handles or LED pins, adjust `huart1`, `hi2c1`, and `GPIOC/GPIO_PIN_13` in `liakia_lab_port_stm32f103.c`.

In `main.c`, include:

```c
#include "liakia_lab_app.h"
```

After peripheral initialization:

```c
LiakiaLab_Init();
```

In the main loop:

```c
while (1)
{
  LiakiaLab_Tick();
}
```

Minimal USART1 byte interrupt bridge:

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

## 5. Run The Normal Application First

Build and flash. The serial console should show:

```text
Liakia Starter-F103 ready
```

Manually send:

```text
version
diag i2c
sensor id
sensor read
telemetry once
```

Expected key output:

```text
SENSOR_ID addr=0x76 id=0x58 result=PASS
RAW_CALIB result=PASS ...
DECODED dig_T1=... dig_T2=... dig_T3=...
RAW_TEMP adc=... result=PASS
COMP_TEMP x100=... result=PASS
DATA_QUALITY result=PASS
TELEMETRY ... crc=... result=PASS
```

The base application tries both `0x76` and `0x77`.

## 6. Run The Baseline Runner

If your project uses CMake presets:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build\Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

If you build from STM32CubeIDE, build in the IDE first, then run:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

If you do not want to flash, pass `-SkipFlash` explicitly. Missing `-Elf` is treated as a failure so the runner does not silently test an old firmware image.

## 7. Inject Case B

For the easiest training path, temporarily change `S16Le` in your copied `liakia_lab_app.c` from:

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

to the known-bad version:

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}
```

This simulates a BMP280 signed calibration endian bug. A reference fragment is also available under `app-layer/known-bad/`.

Rebuild, flash, and run expected-failure mode:

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

The run should produce `EXPECTED_FAIL`, not a clean PASS. The important part is that the evidence package is still generated.

## 8. Generate Diagnosis Material

Given an output directory such as:

```text
C:\work\f103-liakia\evidence-out\starter-f103-20260521-120000
```

run:

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-20260521-120000 `
  -Case case-b
```

Outputs:

```text
ai_prompt.md
failure_triage.md
```

Give `ai_prompt.md` to an AI assistant and require it to reason only from the evidence.

## 9. Fix And Regress

Restore correct little-endian decoding:

```c
static int16_t S16Le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}
```

Rebuild, flash, and re-run the baseline without expected-failure flags:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b
```

Expected result:

```text
build PASS
flash PASS
shell PASS
i2c_scan PASS
sensor_id PASS
data_quality PASS
telemetry_crc PASS
reset_recovery PASS or an explicit recovery log
register_probe PASS or an explicit skip reason
manifest generated
```

## 10. Common Failures

| Symptom | Check first |
|---|---|
| ST-LINK cannot connect | GND, SWDIO/SWCLK, BOOT0, SWD frequency, NRST |
| No serial output | TX/RX crossing, COM port, 115200 8N1, receive interrupt |
| `diag i2c` does not find BMP280 | Power, SDA/SCL, pull-ups, voltage, address |
| `sensor id` passes but `sensor read` fails | calibration endian, signed/unsigned conversion, compensation formula |
| failure after reset | reset recovery, I2C bus recovery, RCC_CSR reset reason |
