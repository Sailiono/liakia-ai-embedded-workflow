# Future Automation Plan

The current repository already provides first-pass scripts:

```text
tools/run_starter_f103.ps1
tools/diagnose_starter_f103.ps1
tools/register_probe_f103.ps1
```

Future work focuses on broader hardware coverage, known-bad application variants, and website interaction.

## Implemented: `run_starter_f103.ps1`

Purpose:

```text
invoke user project build
invoke STM32CubeProgrammer flash
open serial port
run shell / sensor / telemetry gates
generate evidence package
```

Requirements:

- no fixed CubeMX project path;
- user passes build command, ELF path, and COM port;
- failed tests still generate evidence;
- every gate has a log and result;
- manifest records PASS / FAIL / SKIP.

## Implemented: `diagnose_starter_f103.ps1`

Purpose:

```text
read evidence package
summarize failed gates
generate AI prompt
generate failure_triage.md
```

It does not call an online AI service. It only produces a prompt that can be reviewed and copied.

## Implemented: `register_probe_f103.ps1`

Purpose:

```text
read key registers with STM32CubeProgrammer -r32
decode RCC / GPIO / USART / I2C / FLASH / reset reason
write JSON summary
```

Key registers:

```text
RCC_APB1ENR
RCC_APB2ENR
GPIOA_CRH
GPIOB_CRL
GPIOB_IDR
USART1_BRR
I2C1_CR1
I2C1_SR1
I2C1_SR2
RCC_CSR
FLASH_SR
```

## P1: Known-Bad App Variants

Add application-layer files for:

```text
case-a-bmp280-calibration
case-b-i2c-bus-stuck-reset
case-c-flash-persistence-alignment
case-d-uart-dma-idle-race
```

Each case should include:

```text
known-bad source
expected failing gate
minimal fix hint
regression checklist
```

## P2: Website Interaction Module

Add a Starter Lab walkthrough module to the website:

```text
wiring
IOC
application integration
flash known-bad
observe FAIL
AI diagnosis
fix PASS
evidence package
```

The module should explain the route, not pretend to run hardware in the browser.
