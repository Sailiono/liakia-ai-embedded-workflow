# Case D Answer — Flash Persistence Failure

## Expected Symptom

The immediate readback can appear correct, but the value is not reliable after reset:

```text
config set PASS
config save PASS
config get PASS before reset
reset
config get FAIL after reset
CRC mismatch or unexpected raw record bytes
```

## Root Cause

The imported fragment combines two unsafe persistence patterns:

1. it writes a raw C struct representation as the persisted record;
2. it simulates Flash programming with byte-level `&=` into the existing shadow page without a proper erase/write contract.

The code path can make a RAM-shadow readback look plausible while the actual persisted representation is not a stable, versioned, erased, aligned Flash record.

## Minimal Fix

Use an explicit serialized record format instead of raw struct bytes:

```text
magic
version
length
payload bytes in fixed order
CRC over exactly magic/version/length/payload
```

Then enforce the target Flash rules:

- erase the target page before writing a new record;
- program using the required halfword/word width for the target MCU;
- verify by reading back from Flash, not from the RAM shadow;
- reject records with wrong magic, version, length, or CRC.

## Regression

The fix is credible only when:

```text
config save PASS
immediate readback PASS
software reset
post-reset readback PASS
raw record CRC PASS
manifest records the persistence gate result
```
