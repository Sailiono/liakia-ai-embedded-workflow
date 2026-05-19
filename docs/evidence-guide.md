# Evidence Package Guide

Evidence package is the handoff artifact for this workflow. It records what was built, how it was flashed, which tests ran, what failed or passed, and which logs can be reviewed later.

The goal is not to prove that AI is always correct. The goal is to make embedded delivery auditable.

## Directory Layout

```text
evidence/baseline-2026-05-18/
├── 00_manifest.json
├── 01_environment_check.log
├── 02_build_debug.log
├── 03_flash_verify.log
├── 04_shell_test.log
├── 05_rtcm_parse.log
├── 06_register_probe.log
├── firmware_sha256.txt
├── test_summary.md
└── handoff_report.md
```

## Review Checklist

- Build output exists and contains no fatal errors.
- Flash / verify / reset was completed by a repeatable command.
- Serial shell commands were tested by script, not manual memory.
- RTCM frames were parsed and CRC bad count is recorded.
- Register probes are captured when a hardware-level diagnosis is needed.
- Human reviewer signs off before the evidence package is used as a delivery result.

## Minimum Hard-Evidence Fields

Each production-grade run should include:

- `timestamp_start` and `timestamp_end`;
- operator or reviewer;
- source branch and commit SHA;
- clean/dirty working-tree state;
- toolchain version;
- firmware artifact size and SHA256;
- serial port names and baudrate;
- protocol parser result with non-zero exit on failure;
- register addresses, raw values, and bit decode where register probing is used.

Public showcase logs in this repository are sanitized examples. For customer acceptance, rerun the workflow on the target bench and attach raw CubeProgrammer, serial, parser, and register probe transcripts.

## Human-In-The-Loop Rule

AI can summarize logs and propose root causes, but the final judgement remains with the engineer. Safety-related changes, hardware assumptions, clock-tree changes, flash layout changes, and production configuration changes require explicit human review.
