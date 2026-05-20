# Failure-To-Fix Case Studies

These case studies show how the workflow handles embedded failures:

1. Capture symptoms.
2. Generate hypotheses.
3. Collect logs and register evidence.
4. Let AI summarize and propose root cause.
5. Let the engineer confirm.
6. Apply a minimal fix.
7. Run regression tests.
8. Archive evidence.

The cases are written as public workflow examples. They intentionally avoid private lab notes and customer-specific information.

## Cases

| Case | Type | Evidence level |
|---|---|---|
| [Case 01 — USART clock missing](01-usart-clock-missing.md) | Public failure-to-fix replay | Medium-high |
| [Case 02 — RS422 DE timing](02-rs422-de-timing.md) | Diagnosis pattern with regression target | Medium |
| [Case 03 — RTCM CRC validation](03-rtcm-crc-validation.md) | Validation pattern and parser gate | Medium |
| [Case 04 — USB CDC reset recovery](04-usb-cdc-reset-recovery.md) | Real bench replay | High |

Case 04 is the current featured example because it shows a real failure becoming a repeatable regression gate inside the same baseline run.
