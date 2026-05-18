# Code Review Policy

## AI Must Check

- touched files are scoped to the requirement;
- no unrelated refactor;
- compiler warnings are not ignored;
- tests or evidence match the risk level;
- hardware assumptions are documented.

## Human Must Review

- clock tree changes;
- flash layout changes;
- watchdog strategy changes;
- protocol boundary changes;
- production defaults;
- safety-related behaviour.
