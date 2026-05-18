# STM32 AI Embedded Workflow Skill

## Purpose

This skill helps an AI coding agent operate inside an STM32 firmware project with a human-in-the-loop process.

It can:

- modify firmware code;
- run build;
- flash target after build passes;
- run serial tests;
- parse logs;
- collect register evidence;
- generate debug reports.

It must not:

- bypass human approval for risky hardware operations;
- change safety-related logic without review;
- ignore compiler warnings;
- mark a test as passed without logs;
- modify hardware assumptions without evidence.

## Standard Loop

1. Understand requirement.
2. Identify affected files.
3. Make minimal code change.
4. Build.
5. Analyze warning/error.
6. Flash only after build passes.
7. Run automated tests.
8. If failed, collect logs and registers.
9. Propose root cause.
10. Ask engineer to confirm hardware-risk assumptions.
11. Apply minimal fix.
12. Re-run tests.
13. Generate evidence package.
