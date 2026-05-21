# Case D: Flash Config Persistence Alignment Bug

## 1. Why This Case Matters

Configuration persistence often looks simple, but real firmware can fail in subtle ways:

```text
immediate readback works
after reset, config is lost
fields are shifted
old config is misinterpreted after a version change
```

This is a strong automation case because manual "set and look" testing often misses post-reset state.

## 2. Expected Symptoms

```text
config set threshold 2500
config get -> threshold=2500 PASS
config save -> PASS
reset
config get -> threshold=0 or invalid FAIL
```

## 3. Possible Root Causes

- F103 Flash half-word write granularity handled incorrectly;
- page erase address is wrong;
- struct padding is not fixed;
- CRC includes uninitialized padding;
- version / length fields are not checked;
- byte writes are used where hardware expects half-word writes.

## 4. Evidence To Collect

Command output:

```text
config get
config set threshold 2500
config save
config get
reset
config get
```

Flash raw dump:

```text
config page base address
magic
version
length
crc
raw payload hex
decoded fields
```

Registers:

```text
FLASH_SR
FLASH_CR
RCC_CSR reset reason
```

## 5. Expected AI Diagnosis

The AI should separate:

```text
RAM config path
Flash write success
post-reset load address
CRC payload range
stable struct layout
```

If pre-reset PASS and post-reset FAIL, persistence is more likely than the shell parser.

## 6. Fix Direction

Recommended record format:

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
- no dependence on compiler padding;
- initialize reserved bytes before write;
- CRC does not include `crc32` itself;
- Flash writes obey half-word or word constraints;
- raw readback after save;
- verification again after reset.

## 7. PASS Criteria

```text
pre-reset config readback PASS
flash raw readback PASS
post-reset config readback PASS
crc check PASS
manifest records flash page and config version
```

## 8. Demonstration Value

This case is effective for both engineering managers and firmware engineers. It shows Liakia is not just a demo runner; it can turn hidden persistence bugs into reviewable regression evidence.
