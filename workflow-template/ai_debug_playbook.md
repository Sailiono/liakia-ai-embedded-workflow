# AI Debug Playbook

## Standard Loop

1. Restate the failure symptom.
2. List likely causes.
3. Identify the smallest evidence needed.
4. Run build/test/probe commands.
5. Summarize logs without hiding failures.
6. Propose the most likely root cause.
7. Ask for human confirmation when hardware risk exists.
8. Apply the smallest fix.
9. Re-run regression.
10. Archive evidence.

## Rules

- Do not flash if build failed.
- Do not mark a test as passed without logs.
- Do not write registers without explicit human approval.
- Do not change safety or hardware assumptions silently.
- Do not bury compiler warnings.
