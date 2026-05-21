# Starter-F103 Lab 任务剧情

## 任务目录

| Mission | 文档 | 目标 |
|---|---|---|
| 00 | [硬件连接与上电检查](00-hardware-check.zh-CN.md) | 让 ST-LINK、串口、I2C 物理链路可验证 |
| 01 | [CubeMX / IOC 空工程](01-cubemx-ioc.zh-CN.md) | 用户自己生成底层 HAL 工程 |
| 02 | [应用层接入](02-app-layer-integration.zh-CN.md) | 把 Liakia app-layer 接入用户工程 |
| 03 | [BMP280 Bringup](03-bmp280-bringup.zh-CN.md) | 证明 I2C、chip id、telemetry 能跑 |
| 04 | [Known-bad 诊断](04-known-bad-diagnosis.zh-CN.md) | 烧录有问题的应用层并采集证据 |
| 05 | [修复与回归](05-fix-and-regression.zh-CN.md) | 修复问题并生成 evidence package |

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
