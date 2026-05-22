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

The Starter Lab is not a fake PASS demo. It gives you four intentionally broken application-layer cases. Run the baseline first, import a broken case, diagnose the symptom manually, then give the same evidence to AI and compare the diagnostic path before opening the answer key.

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

Detailed parts notes: [bom.md](bom.md).

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

Full wiring notes: [wiring.md](wiring.md).

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

Detailed IOC checkpoints: [cubemx-ioc-guide.md](cubemx-ioc-guide.md).

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

Detailed integration contract: [app-layer/README.md](app-layer/README.md).

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
  -Case case-a
```

If you build from STM32CubeIDE, build in the IDE first, then run:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-a
```

If you do not want to flash, pass `-SkipFlash` explicitly. Missing `-Elf` is treated as a failure so the runner does not silently test an old firmware image.

## 7. Start the Known-Bad Case Ladder

From here, the lab is no longer just proving that the board works. You use cases A-D to compare two paths: how long it takes to diagnose from logs and code manually, and how much faster or clearer the same evidence becomes when given to AI.

Recommended progression:

| Order | Case | Training Focus | Entry |
|---:|---|---|---|
| 1 | Case A | BMP280 chip ID passes, but data quality fails. Best first exposure to evidence-first diagnosis. | [case-a-bmp280-calibration](known-bad-cases/case-a-bmp280-calibration/README.md) |
| 2 | Case B | I2C recovery fails after reset, requiring reset recovery plus GPIO/I2C state reasoning. | [case-b-i2c-bus-stuck-reset](known-bad-cases/case-b-i2c-bus-stuck-reset/README.md) |
| 3 | Case C | Flash persistence fails across reset, requiring raw record and reload evidence. | [case-c-flash-persistence-alignment](known-bad-cases/case-c-flash-persistence-alignment/README.md) |
| 4 | Case D | UART DMA/IDLE stream boundary failure, requiring rate, truncation, CRC, and frame-boundary analysis. | [case-d-uart-dma-idle-race](known-bad-cases/case-d-uart-dma-idle-race/README.md) |

Each case folder contains:

- `app-layer/`: intentionally broken application-layer files;
- `README.md`: import, run, and evidence collection guide;
- `ANSWER.md`: symptom, root cause, and reference fix, to be opened only after your diagnosis attempt.

Use this loop for every case:

1. Open the selected case `README.md`; read only the import and run steps.
2. Import the broken files from `app-layer/` into your own CubeMX/HAL project.
3. Build, flash, and run the expected-failure gate.
4. Diagnose manually first: record the symptom, hypotheses, ruled-out causes, and elapsed time.
5. Generate the AI prompt and ask AI to reason from the same evidence.
6. Compare manual diagnosis with AI-assisted diagnosis, then open the answer key.

The command below uses Case A as the first example. Other cases define their own import files, expected failure gates, and observation points in their case folders.

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-a `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

The run should produce `EXPECTED_FAIL`, not a clean PASS. The important part is that the evidence package is still generated.

Gate definitions: [test-gates.md](test-gates.md).

## 8. Diagnose Manually, Then Generate AI Material

Do not jump straight to the answer. Spend 15-30 minutes on a manual diagnosis first and write down:

| Item | What to Record |
|---|---|
| Symptom | Which gate failed, what the serial output says, whether reset changes it |
| Ruled-out causes | Power, wiring, I2C address, chip ID, build/flash freshness |
| Your hypothesis | The file, function, state boundary, or timing path you suspect |
| Elapsed time | How long it took to form a defensible hypothesis |

Then generate AI diagnosis material from the same evidence.

Given an output directory such as:

```text
C:\work\f103-liakia\evidence-out\starter-f103-20260521-120000
```

run:

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-20260521-120000 `
  -Case case-a
```

Outputs:

```text
ai_prompt.md
failure_triage.md
```

Give `ai_prompt.md` to an AI assistant and require it to reason only from the evidence.

AI diagnosis contract: [diagnosis-playbook.md](diagnosis-playbook.md).

## 9. Compare, Fix, And Regress

Compare your manual result with the AI result:

| Comparison | Manual Diagnosis | AI-Assisted Diagnosis |
|---|---|---|
| Evidence used | Logs, manifest, serial output you inspected | Logs, gates, registers, or raw values cited by AI |
| Root-cause ranking | Your hypothesis order | AI hypothesis order |
| Minimal fix scope | Files/functions you would edit | Files/functions AI recommends |
| Elapsed time | Your measured time | Prompt generation plus AI analysis time |
| Confidence | Evidence that supports or weakens your conclusion | AI claims accepted or rejected by human review |

Only after that comparison should you open the current case `ANSWER.md`. The answer key is for validation, not for shortcutting the exercise.

After AI diagnosis and human review, apply the minimal fix identified by the evidence. If you are stuck, read the selected case answer, for example [case-a-bmp280-calibration/ANSWER.md](known-bad-cases/case-a-bmp280-calibration/ANSWER.md).

Rebuild, flash, and re-run the baseline without expected-failure flags:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-a
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

Evidence package format: [evidence-template/README.md](evidence-template/README.md).

## 10. Common Failures

| Symptom | Check first |
|---|---|
| ST-LINK cannot connect | GND, SWDIO/SWCLK, BOOT0, SWD frequency, NRST |
| No serial output | TX/RX crossing, COM port, 115200 8N1, receive interrupt |
| `diag i2c` does not find BMP280 | Power, SDA/SCL, pull-ups, voltage, address |
| `sensor id` passes but `sensor read` fails | compare raw bytes, decoded values, data-quality gate, and the imported case file |
| failure after reset | reset recovery, I2C bus recovery, RCC_CSR reset reason |

More troubleshooting notes: [troubleshooting.md](troubleshooting.md).
