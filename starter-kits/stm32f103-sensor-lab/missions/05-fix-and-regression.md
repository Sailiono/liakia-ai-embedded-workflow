# Mission 05: Fix And Regression

This mission closes the debug loop. The fix is not the finish line; regression evidence is.

Do this mission only after you have:

1. imported a known-bad case;
2. reproduced the failing gate;
3. generated the evidence package;
4. asked AI to diagnose from evidence;
5. reviewed the answer key for that case.

## Fix Principles

The fix must:

- be minimal;
- explain why the change is needed;
- match the failed evidence;
- avoid unrelated IOC, HAL, or clock-tree changes;
- rerun the same gates;
- generate a new evidence package.

## Case-Specific Fix

Each known-bad folder has its own answer key:

```text
known-bad-cases/<case-folder>/ANSWER.md
```

Use that answer key to confirm your diagnosis, then apply the smallest code change that matches the evidence. Do not replace a focused fix with a driver rewrite.

## Regression Commands

Manual route:

```text
version
diag i2c
sensor id
sensor read
telemetry once
reset
version
sensor id
```

Automated route:

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -Elf Debug\app.elf `
  -ComPort COMx `
  -Case case-a
```

## PASS Criteria

```text
build PASS
flash PASS
shell PASS
i2c scan PASS
sensor id PASS
data quality PASS
telemetry CRC PASS
reset recovery PASS or explicit skip reason
manifest GENERATED
```

## Handoff Summary Template

After the fix, produce a short handoff:

```text
Issue:
  What failed, using gate names and exact output.

Evidence:
  Which logs, raw values, and register or memory evidence supported the diagnosis.

Fix:
  File changed, exact code area, and why this is the smallest valid fix.

Regression:
  Gates rerun and PASS criteria.
```
