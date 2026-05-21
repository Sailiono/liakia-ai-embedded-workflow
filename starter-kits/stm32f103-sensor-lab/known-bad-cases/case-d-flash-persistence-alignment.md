# Case D: Flash Config Persistence Regression

## Practice Card

This case validates state persistence across reset. It is a good second-stage case after the BMP280 path works.

Application area:

```text
config record layout
Flash page erase/write path
post-reset config load path
```

Exercise setup:

1. Add or enable `config get`, `config set`, and `config save`.
2. Save one value.
3. Verify immediate readback.
4. Trigger software reset.
5. Verify post-reset readback.
6. If it fails, dump the raw record and generate diagnosis material.

Observe:

```text
pre-reset config readback
post-reset config readback
raw Flash record
CRC result
record version
record length
```

## Stop Here For The Exercise

Everything below this line is the answer key.

## Answer Key

Typical symptom:

```text
config set threshold 2500
config get -> threshold=2500 PASS
config save -> PASS
reset
config get -> threshold=0 or invalid FAIL
```

Likely root cause family:

- F103 Flash half-word write granularity handled incorrectly;
- page erase address is wrong;
- struct padding is not fixed;
- CRC includes uninitialized padding;
- version / length fields are not checked;
- byte writes are used where hardware expects half-word writes.

Fix direction:

```c
typedef struct {
  uint32_t magic;
  uint16_t version;
  uint16_t length;
  uint32_t crc32;
  int16_t threshold_x100;
  uint16_t flags;
  uint32_t reserved[4];
} LiakiaConfigRecord;
```

Requirements:

- fixed field widths;
- initialized reserved fields;
- CRC excludes `crc32` itself;
- Flash writes obey half-word or word constraints;
- raw readback after save;
- verification again after reset.

Regression:

```text
pre-reset config readback PASS
flash raw readback PASS
post-reset config readback PASS
crc check PASS
manifest records flash page and config version
```
