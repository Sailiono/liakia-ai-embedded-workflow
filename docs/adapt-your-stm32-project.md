# Adapt Your STM32 Project To FirmwareProof

FirmwareProof is not tied to the dpiny-RTK firmware. The goal is to wrap an existing STM32 project with a repeatable delivery loop:

```text
build -> flash -> serial tests -> protocol gates -> register probe -> evidence package
```

This guide describes what is needed to connect another STM32 firmware project to the same workflow style.

## 1. What The Customer Provides

For a first integration, the project owner should provide:

| Item | Purpose |
|---|---|
| Firmware repository or export | Build and test integration point |
| MCU and board information | Flash target, memory map, register probe scope |
| Existing build command | CMake, Make, CubeIDE headless, or another reproducible build entry |
| Flash method | ST-LINK, J-Link, DFU, bootloader, or vendor CLI |
| Serial interfaces | Shell port, debug port, protocol output port, baud rates |
| Basic test expectations | Commands, expected keywords, protocol frames, error boundaries |
| Hardware risk notes | Power, reset, boot pins, isolation, safety boundaries |
| Handoff expectations | What evidence the team wants after each run |

## 2. Define The Adapter

FirmwareProof uses an adapter-style description so the workflow can stay generic while project details remain explicit.

Example:

```json
{
  "project": {
    "name": "customer-stm32-board",
    "root": "../customer-firmware",
    "elf": "build/Debug/customer.elf"
  },
  "build": {
    "command": "ninja",
    "working_dir": "build/Debug"
  },
  "flash": {
    "tool": "STM32_Programmer_CLI",
    "connect": "port=SWD freq=4000",
    "verify": true,
    "reset": true
  },
  "serial": {
    "shell_port": "COM4",
    "rtcm_port": "COM6",
    "baudrate": 115200
  },
  "tests": [
    {
      "name": "shell",
      "script": "tools/test_shell.ps1",
      "args": {
        "Port": "COM4",
        "OutputJson": "evidence-out/shell_summary.json"
      }
    }
  ],
  "register_probe": {
    "enabled": true,
    "targets": ["rcc", "gpio", "usart", "fault"]
  }
}
```

## 3. Connect Build And Flash

The first milestone is a reproducible command-line build and a flash transcript:

```powershell
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage build
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage flash
```

Recommended evidence:

- toolchain version;
- build command and working directory;
- compiler warnings or errors;
- ELF / HEX / BIN size;
- artifact SHA256;
- flash verify log;
- reset method.

## 4. Add Serial Gates

Start with a small set of commands that prove the firmware is alive and configurable.

Typical shell gates:

| Gate | Example |
|---|---|
| Identity | `version` returns project name and firmware version |
| Health | `status` returns task, uptime, or interface state |
| Config | `config` returns current persisted settings |
| Input validation | invalid command is rejected without crashing the shell |
| Reset recovery | shell still responds after software reset |

The key rule: a test must have a clear PASS/FAIL exit code, not only human-readable output.

## 5. Add Protocol Or Domain Gates

For dpiny-RTK, the protocol gate is RTCM CRC validation. Another project may use a different domain gate:

| Project type | Possible gate |
|---|---|
| Sensor gateway | frame count, CRC, timestamp monotonicity |
| Motor controller | command response, fault status, current limit state |
| Industrial I/O | Modbus request/response, input state matrix |
| Flight peripheral | telemetry packet parse, heartbeat timeout |
| GNSS / RTK | RTCM frame parse, CRC, message type coverage |

The protocol gate should fail on missing frames, invalid CRC, missing required message types, or impossible values.

## 6. Add Register Evidence

Register probes are not meant to replace debugging. They create a low-level evidence snapshot when a gate fails.

Useful first targets:

- CPU fault state;
- reset flags;
- RCC clock enable registers;
- GPIO mode and alternate function registers;
- USART / SPI / I2C control and status registers;
- USB state registers if the project exposes USB CDC.

The public template uses read-only probes. Any register write should be treated as a risky action and require human approval.

## 7. Generate The Evidence Package

The end state is a folder that another engineer or manager can review without replaying the whole conversation.

Recommended output:

```text
evidence-out/
  manifest.json
  logs/
    environment.log
    build.log
    flash.log
    shell.log
    protocol.log
    register_probe.log
  summaries/
    shell_summary.json
    protocol_summary.json
    register_probe_summary.json
  handoff_report.md
```

The manifest should be generated even when a gate fails. Failure evidence is often more valuable than a clean PASS.

## 8. Typical One-Week Pilot Scope

A realistic first pilot for an existing STM32 firmware project:

| Day | Deliverable |
|---|---|
| 1 | Build and flash commands made reproducible |
| 2 | Shell or serial smoke tests connected |
| 3 | One protocol or domain gate added |
| 4 | Register probe and failure evidence format added |
| 5 | Baseline runner, manifest, and handoff report reviewed with the engineering team |

Out of scope for a one-week pilot:

- PCB redesign;
- EMC / ESD qualification;
- safety certification;
- production fixture design;
- replacing the team's firmware framework or IDE.

## 9. Human Review Boundary

FirmwareProof should keep the final engineering decision with humans.

Human review is required for:

- flash layout or boot configuration changes;
- watchdog policy changes;
- safety-related behavior;
- register writes;
- power, isolation, or external load assumptions;
- any evidence that conflicts with the proposed root cause.

## 10. Result

After integration, the team should be able to run one command and get:

- build result;
- flash result;
- serial test result;
- protocol gate result;
- register evidence when needed;
- manifest and handoff report;
- a clear PASS/FAIL boundary for the next engineering decision.
