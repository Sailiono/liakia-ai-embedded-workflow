# Case D：Flash Config Persistence Alignment Bug

## 1. 为什么这个 case 重要

很多嵌入式项目的配置保存逻辑看起来很简单，但实际容易出现：

```text
立即读取正常
reset 后丢失
字段错位
版本升级后旧配置解释错误
```

这类问题很适合展示自动化回归，因为人工“设一下、看一下”很容易漏掉 reset 后状态。

## 2. 预期现象

```text
config set threshold 2500
config get -> threshold=2500 PASS
config save -> PASS
reset
config get -> threshold=0 or invalid FAIL
```

## 3. 可能根因

- F103 Flash half-word 写入粒度处理错误；
- page erase 地址不对；
- struct padding 没有固定；
- CRC 计算时包含了未初始化 padding；
- version / length 字段没有参与校验；
- 写入时按 byte 写，实际硬件只支持 half-word。

## 4. 应收集证据

命令输出：

```text
config get
config set threshold 2500
config save
config get
reset
config get
```

Flash raw dump：

```text
config page base address
magic
version
length
crc
raw payload hex
decoded fields
```

寄存器：

```text
FLASH_SR
FLASH_CR
RCC_CSR reset reason
```

## 5. AI 诊断期望

AI 应该区分：

```text
RAM config path 是否正常
Flash write 是否成功
reset 后 load 是否读取正确地址
CRC 是否覆盖同一段 payload
struct layout 是否稳定
```

如果 pre-reset PASS、post-reset FAIL，优先怀疑 persistence path，而不是 Shell parser。

## 6. 修复方向

推荐配置格式：

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
- 不依赖编译器 padding；
- 写入前先填充 reserved；
- CRC 不覆盖 `crc32` 字段本身；
- Flash 写入按 half-word 或 word 约束实现；
- 保存后立即 raw readback；
- reset 后再验证。

## 7. 通过标准

```text
pre-reset config readback PASS
flash raw readback PASS
post-reset config readback PASS
crc check PASS
manifest records flash page and config version
```

## 8. 展示价值

这个 case 对中层和工程师都有效。它说明 Liakia 不只是“能跑 demo”，而是能把隐蔽的状态持久化问题变成可审查、可回归的证据。
