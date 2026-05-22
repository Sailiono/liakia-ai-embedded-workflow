# Learn It — Starter-F103 Sensor Lab

[中文说明](README.zh-CN.md) | English

This path is for readers who want to **feel the workflow on their own bench** instead of only reading evidence from someone else's project.

You will use a low-cost STM32F103C8T6 board, a BMP280 sensor, ST-LINK, and a USB-UART adapter to run a small firmware lab. The learning goal is not a fake demo that always passes. The goal is to build a normal baseline, import intentionally broken application-layer code, collect evidence, compare manual debugging with AI-assisted diagnosis, and then fix the issue.

## What You Will Experience

```text
wire the board
-> generate CubeMX IOC
-> integrate Liakia app layer
-> build and flash
-> pass the baseline
-> import a known-bad case
-> collect failing evidence
-> diagnose manually first
-> ask AI with the same evidence
-> fix and regress to PASS
```

## Hardware

| Item | Purpose |
|---|---|
| STM32F103C8T6 board | Target MCU, commonly sold as Blue Pill compatible boards. |
| ST-LINK | SWD programming and debug connection. |
| USB-UART adapter | Shell and evidence collection. |
| BMP280 module | I2C sensor used for realistic known-bad cases. |
| Dupont wires | SWD, UART, I2C, power, and ground wiring. |
| Pull-up resistors | I2C pull-ups when the BMP280 module does not include reliable pull-ups. |

## The Four-Case Ladder

The cases are intentionally not all equally easy. They are designed to show where AI-assisted evidence analysis becomes useful.

| Recommended order | Case | What it trains |
|---:|---|---|
| 1 | Case A — BMP280 data quality | I2C and chip ID pass, but decoded sensor data is not credible. |
| 2 | Case B — I2C reset recovery | The bus can fail after reset, requiring state and recovery reasoning. |
| 3 | Case C — Flash persistence | A value saves but does not survive reset correctly. |
| 4 | Case D — UART DMA/IDLE stream | Stream boundaries and timing create a harder diagnosis problem. |

Each case folder contains broken app-layer files, a practice guide, and a separate answer key. Do not open the answer key before your own attempt.

## How To Use AI Here

Use AI as a diagnosis partner, not as an oracle.

1. Run the failing case bnd generate evidence.
2. Spend 15-30 minutes diagnosing manually.
3. Record the symptom, ruled-out causes, hypothesis, and elapsed time.
4. Generate `ai_prompt.md`.
5. Ask AI to reason only from logs, gate results, raw values, and manifests.
6. Compare your path with the AI path.
7. Open the answer key only after the comparison.

## Start

Follow the full quick start:

- [Starter-F103 Quick Start](../../starter-kits/stm32f103-sensor-lab/quick-start.md)

Then open the case index:

- [Known-bad case packs](../../starter-kits/stm32f103-sensor-lab/known-bad-cases/README.md)

Beginner web page:

- [Beginner page](https://sailiono.github.io/liakia-ai-embedded-workflow/promo-demo/beginner.en.html)

## What To Read Next

After completing one case, inspect:

- [diagnosis playbook](../../starter-kits/stm32f103-sensor-lab/diagnosis-playbook.md)
- [test gates](../../starter-kits/stm32f103-sensor-lab/test-gates.md)
- [evidence template](../../starter-kits/stm32f103-sensor-lab/evidence-template/README.md)

If you want to verify the stronger engineering proof, continue to:

- [Trust it](../trust-it/README.md)
