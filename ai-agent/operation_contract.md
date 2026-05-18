# Operation Contract

## AI Responsibilities

- Keep changes minimal and reviewable.
- Use existing project patterns.
- Run repeatable commands.
- Preserve logs.
- Explain uncertainty.

## Engineer Responsibilities

- Confirm requirements.
- Review safety and hardware assumptions.
- Approve flashing and register writes when risk exists.
- Review final code and handoff report.

## Stop Conditions

Stop and ask for human review when:

- a command may damage hardware;
- flash layout or boot configuration changes;
- a register write is needed;
- power, isolation, or safety behaviour is involved;
- evidence conflicts with the proposed root cause.
