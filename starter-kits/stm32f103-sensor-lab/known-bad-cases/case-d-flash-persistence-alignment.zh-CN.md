# Case D：Flash Config Persistence Regression

## 练习卡片

这个 case 验证 reset 前后的状态持久化。建议在 BMP280 路径跑通后作为第二阶段练习。

应用层关注位置：

```text
config record layout
Flash page erase/write path
post-reset config load path
```

练习步骤：

1. 增加或启用 `config get`、`config set`、`config save`；
2. 保存一个配置值；
3. 验证立即读回；
4. 触发 software reset；
5. 验证 reset 后读回；
6. 如果失败，dump raw record 并生成诊断材料。

观察：

```text
pre-reset config readback
post-reset config readback
raw Flash record
CRC result
record version
record length
```

## 练习到这里先停止

下面是答案解析。

## 答案解析

典型现象：

```text
config set threshold 2500
config get -> threshold=2500 PASS
config save -> PASS
reset
config get -> threshold=0 or invalid FAIL
```

常见根因方向：

- F103 Flash half-word 写入粒度处理错误；
- page erase 地址不对；
- struct padding 没有固定；
- CRC 包含未初始化 padding；
- version / length 字段没有校验；
- 以 byte 写入，但硬件要求 half-word 写。

修复方向：

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

要求：

- 固定字段宽度；
- 初始化 reserved fields；
- CRC 不覆盖 `crc32` 自身；
- Flash 写入满足 half-word 或 word 约束；
- save 后 raw readback；
- reset 后再次验证。

回归标准：

```text
pre-reset config readback PASS
flash raw readback PASS
post-reset config readback PASS
crc check PASS
manifest records flash page and config version
```
