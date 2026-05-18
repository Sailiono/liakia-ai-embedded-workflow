# Failure Triage

## Triage Order

1. Reproduce the failure.
2. Capture the exact command and output.
3. Classify failure: build, flash, boot, serial, protocol, timing, reset.
4. List hypotheses.
5. Choose the smallest evidence to separate hypotheses.
6. Collect logs or registers.
7. Propose root cause with confidence level.
8. Apply minimal fix only after review.
9. Re-run regression.

## Confidence Labels

- High: direct evidence confirms the cause.
- Medium: evidence strongly supports the cause but one alternative remains.
- Low: symptom match only; more evidence required.
