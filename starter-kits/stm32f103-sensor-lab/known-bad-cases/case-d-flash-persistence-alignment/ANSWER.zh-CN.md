# Case D 答案 — Flash Persistence 失败

## 预期现象

立即读回可能看起来正确，但 reset 后不可靠：

```text
config set PASS
config save PASS
config get PASS before reset
reset
config get FAIL after reset
CRC mismatch or unexpected raw record bytes
```

## 根因

导入的片段同时包含两个不安全的持久化模式：

1. 直接把 C struct 的内存表示当成持久化 record；
2. 用 byte-level `&=` 在已有 shadow page 上模拟 Flash program，没有明确的 erase/write contract。

这会让 RAM shadow 的立即读回看起来合理，但真正持久化表示并不是稳定、带版本、已擦除、对齐的 Flash record。

## 最小修复

使用显式序列化格式，不要直接保存 raw struct bytes：

```text
magic
version
length
payload bytes in fixed order
CRC over exactly magic/version/length/payload
```

同时遵守目标 MCU 的 Flash 规则：

- 写入新 record 前擦除目标 page；
- 使用目标 MCU 要求的 halfword/word 写入宽度；
- 回读 Flash 验证，而不是只读 RAM shadow；
- magic、version、length、CRC 任一不匹配都拒绝 record。

## 回归验证

只有满足下面条件，修复才可信：

```text
config save PASS
immediate readback PASS
software reset
post-reset readback PASS
raw record CRC PASS
manifest records the persistence gate result
```
