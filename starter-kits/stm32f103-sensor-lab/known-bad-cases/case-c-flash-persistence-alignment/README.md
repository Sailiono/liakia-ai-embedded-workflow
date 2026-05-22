# Case C — Flash Persistence Failure

This is an advanced persistence exercise. It is for users who have already completed the base sensor lab and want to test reset-state and raw-record evidence.

Do not open [ANSWER.md](ANSWER.md) before saving a value, resetting, and collecting the raw record.

## Files In This Pack

```text
case-c-flash-persistence-alignment/
  app-layer/src/liakia_config_case_c.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

Import the source file into your project:

```text
app-layer/src/liakia_config_case_c.c -> Core/Src/liakia_config_case_c.c
```

This file is intentionally a persistence fragment. You wire it into your own `config get`, `config set`, `config save`, and `config dump` commands.

## Practice Steps

1. Add a small RAM shadow buffer representing one Flash page.
2. Wire `LiakiaCaseD_EncodeRecord()` behind your save command.
3. Wire `LiakiaCaseD_DecodeRecord()` behind your load/read command.
4. Save a test value.
5. Verify immediate readback.
6. Reset the board.
7. Verify post-reset readback.
8. Dump the raw record bytes if the gate fails.

## Evidence To Collect

Collect:

```text
config set value
config save result
immediate config readback
post-reset config readback
raw record bytes
CRC result
record size
Flash write width and erase behavior
```

If you have ST-LINK memory read available, capture the Flash page bytes directly and compare them with the shell dump.

## AI Diagnosis Task

Ask AI:

```text
Use only the config logs and raw record dump.
Explain why immediate readback can appear to pass while post-reset readback fails.
Identify whether this is more likely erase behavior, write width, struct layout, CRC coverage, or versioning.
Suggest the smallest persistence-layer change to inspect first.
```

Then read [ANSWER.md](ANSWER.md).
