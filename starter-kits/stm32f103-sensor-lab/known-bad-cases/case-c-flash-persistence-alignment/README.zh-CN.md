# Case C — Flash Persistence 失败

这是高级持久化练习，适合已经完成基础传感器实验，并希望测试 reset 后状态和原始记录证据的用户。

在保存配置、reset、采集原始记录之前，不要打开 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。

## 文件内容

```text
case-c-flash-persistence-alignment/
  app-layer/src/liakia_config_case_c.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

把源文件导入你的工程：

```text
app-layer/src/liakia_config_case_c.c -> Core/Src/liakia_config_case_c.c
```

这个文件是持久化片段。你需要把它接到自己的 `config get`、`config set`、`config save` 和 `config dump` 命令后面。

## 练习步骤

1. 增加一个代表 Flash page 的 RAM shadow buffer；
2. 在 save 命令里调用 `LiakiaCaseD_EncodeRecord()`；
3. 在 load/read 命令里调用 `LiakiaCaseD_DecodeRecord()`；
4. 保存一个测试值；
5. 验证立即读回；
6. reset 板子；
7. 验证 reset 后读回；
8. 如果检查失败，dump 原始记录字节。

## 需要采集的证据

采集：

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

如果能用 ST-LINK 读内存，直接抓 Flash page bytes，并和 shell dump 对比。

## AI 诊断任务

向 AI 提问：

```text
只能基于 config logs 和 raw record dump。
解释为什么 immediate readback 可能 PASS，但 post-reset readback FAIL。
判断更像 erase behavior、write width、struct layout、CRC coverage，还是 versioning。
建议优先检查哪一个 persistence-layer 代码区域。
```

完成诊断后再阅读 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。
