# Case 04 — USB CDC Shell Recovery After Software Reset

This case turns a real bench issue into an evidence-grade replay: the USB CDC shell could become unavailable after reset, then the workflow added an automated recovery gate and proved the fix with a full build / flash / serial / RTCM baseline.

Public evidence is redacted. User paths, ST-LINK serial number, and USB device serial are intentionally removed from the public log excerpts.

## 1. Incident Context

- Time window: 2026-05-19 to 2026-05-20
- Platform: STM32F407 + FreeRTOS + USB CDC shell
- Reference firmware commit: `eb47ff1`
- Baseline run: `20260520-093713`
- Shell UART: `COM10`
- RTCM stream: `COM5`
- USB CDC shell: `COM12` in the captured baseline
- Test entry: `tools/run_test_baseline.ps1 -BuildPreset Debug -ComPort COM10 -RtcmPort COM5 -UsbPort COM12`

## 2. Symptom

The board could build and flash, but the USB CDC shell was not always usable after connection or software reset.

Observed failure shapes from earlier standalone USB CDC logs:

```text
FAIL: USB CDC shell did not respond within 45 seconds (probe only).
Last state: shell did not answer version
```

Another failure shape:

```text
FAIL: USB CDC shell did not respond within 45 seconds (probe only).
Last state: serial Open/Write failed on the Windows COM device
```

That is exactly the kind of bug that looks small in a demo but hurts real delivery: the firmware appears alive, the port appears in Windows, yet the control shell is not reliably available after reset.

## 3. Automation Gate

The workflow added a dedicated USB CDC reset recovery test:

```powershell
tools/usb_cdc_reset_test.ps1 -UsbPort COM12
```

The gate checks:

- the USB CDC COM port is present;
- `version` responds before software reset;
- the shell accepts `reset`;
- the USB CDC port recovers after reset;
- `version` responds again after recovery.

## 4. Regression Evidence

Full baseline run:

```text
Time: 2026-05-20 09:38:17
Branch: baseline/test-handoff
Commit: eb47ff1
Preset: Debug
Overall: PASS or SKIP only
```

Baseline step results:

```text
Dependency check                 PASS
Build firmware                   PASS
Flash firmware                   PASS
USB CDC post-flash availability  PASS
Functional serial test           PASS
Input validation test            PASS
RTCM stream test                 PASS
USB CDC reset recovery test      PASS
```

USB CDC reset recovery excerpt:

```text
Waiting for USB CDC shell (before software reset)...
>> version
dpiny-RTK Base Station Firmware
  Version: v1.0
  Build:   May 20 2026 09:37:16
  MCU:     STM32F407VET6 @ 168MHz
  GNSS:    Unicore UM982
  RTOS:    FreeRTOS (CMSIS-RTOS v2)

PASS: USB CDC shell responded (before software reset)
>> reset
Waiting for USB CDC to recover after software reset...
Waiting for USB CDC shell (after software reset)...
>> version
dpiny-RTK Base Station Firmware
  Version: v1.0
  Build:   May 20 2026 09:37:16

PASS: USB CDC shell responded (after software reset)
PASS: USB CDC recovered after software reset
```

RTCM gate from the same baseline:

```text
Read 2520 bytes
Total frames found: 28
CRC OK: 28
CRC BAD: 0
MT1005: 6 msgs
MT1074: 6 msgs
MT1084: 6 msgs
MT1094: 6 msgs
MT1124: 4 msgs
PASS: RTCM stream contains expected messages and CRC is clean
```

## 5. Why This Case Matters

This is a stronger story than a happy-path feature checklist:

- the issue was intermittent and hardware-facing;
- Windows showed a COM device, but the shell still failed;
- the fix was not declared complete until a reset recovery gate passed;
- the same run also proved build, flash verify, UART shell, input validation, RTCM CRC, and firmware artifact generation.

For an embedded team, this demonstrates the real value of the workflow: every repair gets converted into a repeatable regression test, so the next reset bug is caught by the bench instead of a customer.
