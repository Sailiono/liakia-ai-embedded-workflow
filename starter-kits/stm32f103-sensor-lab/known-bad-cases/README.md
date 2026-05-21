# Known-Bad Lab Packs

These are hands-on fault-injection packs for the STM32F103C8T6 starter lab.

Each case is a self-contained folder. The folder gives you intentionally broken application-layer or port-layer code, a practice guide, and a separate answer key. Do not open the answer key until you have imported the code, flashed the board, collected evidence, and tried an AI-assisted diagnosis.

The goal is to make the workflow tangible:

```text
import broken app-layer code
build and flash the F103 board
observe the failure
run Liakia gates
collect evidence
ask AI to diagnose from evidence
apply the minimal fix
rerun regression
then read the answer key
```

## Case Folders

| Case | Practice guide | Code to import | Level |
|---|---|---|---|
| Case B: BMP280 data quality failure | [case-b-bmp280-calibration/README.md](case-b-bmp280-calibration/README.md) | complete `liakia_lab_app.c` replacement | First runnable case |
| Case A: I2C reset recovery failure | [case-a-i2c-bus-stuck-reset/README.md](case-a-i2c-bus-stuck-reset/README.md) | `liakia_lab_port_stm32f103.c` replacement | Hardware-state case |
| Case C: UART DMA/IDLE stream failure | [case-c-uart-dma-idle-race/README.md](case-c-uart-dma-idle-race/README.md) | DMA/IDLE receive fragment | Advanced serial case |
| Case D: Flash persistence failure | [case-d-flash-persistence-alignment/README.md](case-d-flash-persistence-alignment/README.md) | config persistence fragment | Advanced persistence case |

## Recommended Order

Start with **Case B**. It uses the same BMP280 wiring as the base starter lab and can be reproduced without extending the IOC beyond USART1, I2C1, GPIO, and SWD.

After Case B, use the other packs according to the capability you want to test:

- use Case A to exercise reset-state evidence and I2C recovery reasoning;
- use Case C to exercise high-rate serial framing and DMA/IDLE diagnostics;
- use Case D to exercise persistence, reset recovery, raw record inspection, and regression gates.

## Common Exercise Rules

1. Build and run the normal base application first.
2. Back up the working file before importing a known-bad file.
3. Import only one case at a time.
4. Do not change CubeMX-generated HAL code unless the case guide explicitly asks for an IOC extension.
5. Treat the first failing run as expected. The important output is the evidence package, not a clean PASS.
6. Give AI the generated evidence and ask it to reason from logs, raw values, and gate results only.
7. Read `ANSWER.md` only after your own diagnosis attempt.

## Runner Pattern

Most cases use the same runner shape:

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

Generate an AI diagnosis packet from the evidence directory:

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-b
```

Use each case guide for the exact import path and expected gate name.
