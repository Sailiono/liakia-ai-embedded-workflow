# Known-Bad Application Layer

This folder contains application-layer fragments that can be integrated into a user-generated HAL project. It does not contain IOC files, HAL initialization code, or a complete flashable project.

User flow:

```text
1. Generate an STM32F103C8T6 project with CubeMX
2. Integrate app-layer/include and app-layer/src
3. Select a known-bad application case
4. Build, flash, and run Liakia gates
5. Use evidence to locate the issue
6. Apply the minimal fix in the application layer or IOC config
```

## First Known-Bad Case

| Case | File | Expected symptom |
|---|---|---|
| Case B: BMP280 calibration / compensation issue | [case_b_bmp280_calibration/liakia_bmp280_case_b.c](case_b_bmp280_calibration/liakia_bmp280_case_b.c) | `sensor id PASS`, but `sensor read` or data-quality gate FAIL |

## Recommended Injection Method

For the shortest beginner path, follow the practice card in:

```text
../../known-bad-cases/case-b-bmp280-calibration.md
```

That page tells you how to inject the bug without explaining the root cause first. The files under `case_b_bmp280_calibration/` show the issue as an isolated application-layer fragment for code review and AI diagnosis. They are not a complete CubeMX project.

The case is not a wrong I2C address. It simulates a more useful engineering condition:

```text
bus works
chip id is correct
raw bytes are readable
but compensated temperature is not credible
```

This demonstrates Liakia's value: protocol and data-quality gates can stop code that "appears to work" and keep AI analysis evidence-scoped.

Read the answer key only after running the gate and generating diagnosis material.
