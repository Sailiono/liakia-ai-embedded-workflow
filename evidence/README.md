# Liakia Evidence Packages

This directory contains public, redacted evidence packages for the Liakia AI-assisted embedded delivery workflow.

| Package | Type | Purpose | Result |
|---|---|---|---|
| [public-showcase-baseline-2026-05-18](public-showcase-baseline-2026-05-18/) | Showcase sample | Demonstrates the evidence format and handoff structure | PASS |
| [realrun-redacted-2026-05-20](realrun-redacted-2026-05-20/) | Real bench run | Local hardware validation with build, flash, serial tests, RTCM CRC, and USB CDC recovery | PASS |
| [remote-hil-redacted-2026-05-20](remote-hil-redacted-2026-05-20/) | Remote HIL run | Remote bench execution with evidence pullback, RTCM 52 frames, and CRC BAD 0 | PASS |

## Redaction Policy

Public evidence removes local Windows user paths, machine names, local IP addresses, SSH key paths, ST-LINK serial numbers, USB PNP serials, and private lab notes.

Customer handoff packages should keep the raw bench logs in the private delivery archive so the result can still be audited by the receiving team.

## How To Read The Packages

- `00_manifest.json`: machine-readable run metadata, test results, artifacts, and redaction notes.
- `test_summary.md`: human-readable summary for engineering managers and reviewers.
- `*.log`: selected command transcripts or redacted extracts from the test run.
