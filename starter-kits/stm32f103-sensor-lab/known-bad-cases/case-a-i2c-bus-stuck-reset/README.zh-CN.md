# Case A — I2C Reset Recovery 失败

这是硬件状态类练习。建议先让基础 BMP280 Lab 跑通，再做 reset-recovery gate 或手工 reset 对比。

在采集冷启动和 software reset 后的证据之前，不要打开 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。

## 文件内容

```text
case-a-i2c-bus-stuck-reset/
  app-layer/port-template/liakia_lab_port_stm32f103.c
  README.md
  README.zh-CN.md
  ANSWER.md
  ANSWER.zh-CN.md
```

把这个文件导入你自己用 CubeMX 生成的工程：

```text
app-layer/port-template/liakia_lab_port_stm32f103.c -> Core/Src/liakia_lab_port_stm32f103.c
```

`liakia_lab_app.c` 继续使用正常基础版本。

## 练习步骤

1. 先确认基础 app 在冷启动后能 PASS；
2. 备份当前可工作的 `Core/Src/liakia_lab_port_stm32f103.c`；
3. 用本 case 文件夹中的 port 文件替换它；
4. 重新编译并烧录；
5. 冷启动后运行：

```text
diag i2c
sensor id
sensor read
```

6. 从 shell 触发 software reset：

```text
reset
```

7. 板子恢复后再次运行同样命令。

## 需要采集的证据

采集 reset 前后日志：

```text
diag i2c
sensor id
sensor read
reset
diag i2c
sensor id
sensor read
```

如果已经启用 ST-LINK register probe，额外抓：

```text
RCC_CSR
GPIOB_IDR
I2C1_SR1
I2C1_SR2
I2C1_CR1
```

## AI 诊断任务

向 AI 提问：

```text
只能基于 reset 前后日志和 register probe。
对比 cold boot 和 software reset 后的行为。
判断更像接线、设备地址，还是 reset-state recovery 问题。
建议优先检查哪一个 platform-layer 函数。
```

完成诊断后再阅读 [ANSWER.zh-CN.md](ANSWER.zh-CN.md)。
