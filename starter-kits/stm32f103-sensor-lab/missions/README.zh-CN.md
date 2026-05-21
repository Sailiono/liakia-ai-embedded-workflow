# Starter-F103 Lab 任务剧情

## Mission 00：准备硬件

目标：

- 焊好排针；
- 接好 SWD；
- 能用 STM32CubeProgrammer 连接目标板；
- 确认芯片型号和 Flash 大小；
- 确认 BOOT0 处于正常启动状态。

通过标准：

```text
ST-LINK connect PASS
target voltage visible
device id readable
```

## Mission 01：从空工程生成 IOC

目标：

- 用户自己创建 STM32F103C8Tx 工程；
- 配置 SYS / RCC / GPIO / USART1 / I2C1；
- 生成 HAL 代码；
- 编译空工程。

通过标准：

```text
generated project build PASS
no user application code yet
```

## Mission 02：接入 Liakia 应用层

目标：

- 复制 Liakia app-layer 文件；
- 实现 platform bridge；
- 在 main.c 中调用 `LiakiaLab_Init()` 和 `LiakiaLab_Tick()`；
- 能通过串口看到 shell banner。

通过标准：

```text
shell version PASS
led command PASS
```

## Mission 03：BMP280 Bringup

目标：

- 接入 BMP280；
- 读取 chip id；
- 读取 calibration bytes；
- 输出一帧 sensor telemetry。

通过标准：

```text
sensor id PASS
raw calibration read PASS
telemetry frame emitted
```

## Mission 04：烧录 Known-Bad 应用层

目标：

- 切换到 known-bad app-layer；
- 运行 baseline；
- 观察至少一个 gate 失败。

预期结果：

```text
build PASS
flash PASS
shell PASS
sensor/protocol/reset/persistence one or more FAIL
evidence package GENERATED
```

## Mission 05：AI 辅助诊断

目标：

- 把 shell log、sensor summary、register snapshot、raw frame summary 提供给 AI；
- 让 AI 给出假设列表；
- 让 AI 标注需要人工确认的硬件假设。

通过标准：

```text
root cause hypothesis is evidence-backed
fix scope is limited to application layer or IOC config
```

## Mission 06：修复与回归

目标：

- 用户修改应用层或 IOC；
- 重新生成/编译/烧录；
- 重新运行 baseline；
- 输出 evidence manifest。

通过标准：

```text
all gates PASS
manifest generated
handoff summary generated
```
