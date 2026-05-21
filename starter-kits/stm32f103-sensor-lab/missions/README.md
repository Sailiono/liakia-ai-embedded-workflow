# Starter-F103 Lab Missions

## Mission Index

| Mission | Document | Goal |
|---|---|---|
| 00 | [Hardware connection and power check](00-hardware-check.md) | Make ST-LINK, UART, and I2C links observable |
| 01 | [CubeMX / IOC empty project](01-cubemx-ioc.md) | Generate the low-level HAL project yourself |
| 02 | [Application layer integration](02-app-layer-integration.md) | Integrate the Liakia app layer into the generated project |
| 03 | [BMP280 bringup](03-bmp280-bringup.md) | Prove I2C, chip ID, and telemetry are working |
| 04 | [Known-bad diagnosis](04-known-bad-diagnosis.md) | Flash a broken application layer and collect evidence |
| 05 | [Fix and regression](05-fix-and-regression.md) | Fix the issue and generate evidence for the passing run |

## Mission 00: Prepare Hardware

Goals:

- solder headers;
- connect SWD;
- connect with STM32CubeProgrammer;
- confirm chip identity and Flash size;
- confirm BOOT0 is in normal boot state.

PASS:

```text
ST-LINK connect PASS
target voltage visible
device id readable
```

## Mission 01: Generate IOC From Empty Project

Goals:

- create the STM32F103C8Tx project yourself;
- configure SYS / RCC / GPIO / USART1 / I2C1;
- generate HAL code;
- build the empty project.

PASS:

```text
generated project build PASS
no user application code yet
```

## Mission 02: Integrate Liakia Application Layer

Goals:

- copy Liakia app-layer files;
- implement the platform bridge;
- call `LiakiaLab_Init()` and `LiakiaLab_Tick()` in `main.c`;
- see the shell banner over UART.

PASS:

```text
shell version PASS
led command PASS
```

## Mission 03: BMP280 Bringup

Goals:

- connect BMP280;
- read chip ID;
- read calibration bytes;
- emit one sensor telemetry frame.

PASS:

```text
sensor id PASS
raw calibration read PASS
telemetry frame emitted
```

## Mission 04: Flash Known-Bad Application Layer

Goals:

- inject the known-bad application bug;
- run the baseline;
- observe at least one failed gate.

Expected result:

```text
build PASS
flash PASS
shell PASS
sensor/protocol/reset/persistence one or more FAIL
evidence package GENERATED
```

## Mission 04B: AI-Assisted Diagnosis

Goals:

- provide shell logs, sensor summary, register snapshot, and raw frame summary to AI;
- ask for ranked hypotheses;
- require the AI to mark assumptions that need human confirmation.

PASS:

```text
root cause hypothesis is evidence-backed
fix scope is limited to application layer or IOC config
```

## Mission 05: Fix And Regress

Goals:

- modify the application layer or IOC;
- rebuild and flash;
- rerun baseline;
- write evidence manifest.

PASS:

```text
all gates PASS
manifest generated
handoff summary generated
```
