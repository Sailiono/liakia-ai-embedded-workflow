# AI 诊断 Playbook

这个文档定义 Starter-F103 Lab 中如何向 AI 提供信息，以及 AI 应该如何约束自己的判断。

## 不推荐的问法

```text
我的传感器读不出来，帮我看看。
```

这种问法信息不足，AI 只能猜。

## 推荐输入结构

```text
目标：
  我在 STM32F103C8T6 + BMP280 Lab 中运行 known-bad Case B。

硬件：
  MCU: STM32F103C8T6
  Sensor: BMP280
  I2C: I2C1 PB6/PB7 100 kHz
  UART: USART1 PA9/PA10 115200
  Debug: ST-LINK SWD

当前现象：
  sensor id PASS
  raw sensor/protocol bytes readable
  后续某个 data-quality gate FAIL
  data-quality gate FAIL

日志：
  粘贴 version / diag i2c / sensor id / sensor read / telemetry once 输出

相关代码：
  粘贴导入的 known-bad app-layer 文件，或最小可疑函数

约束：
  先排查应用层；
  不假设硬件坏，除非证据支持；
  不做无关重构；
  给出需要人工确认的点。
```

## AI 输出格式

要求 AI 按以下格式输出：

```markdown
## Observations

- 已确认事实
- 未确认事实

## Ruled Out

- 通过证据排除的方向

## Hypotheses

| Rank | Hypothesis | Evidence | How to confirm |
|---|---|---|---|

## Minimal Fix

- 修改文件
- 修改点
- 不改什么

## Regression Plan

- 重新运行哪些 gate
- PASS 标准
```

## Case B 示例提示词

```text
你是嵌入式固件调试助手。请基于证据分析，不要凭空猜硬件损坏。

项目：Liakia Starter-F103 Sensor Lab
硬件：STM32F103C8T6 + BMP280
接口：I2C1 PB6/PB7, 100 kHz; USART1 PA9/PA10, 115200

现象：
- version PASS
- diag i2c found 0x76
- sensor id returns 0x58 PASS
- raw sensor bytes are readable
- a later data-quality gate FAILs
- data-quality gate FAIL

请分析：
1. 哪些方向可以排除；
2. 最可能的 3 个根因；
3. 需要检查哪些代码片段；
4. 最小修复应该在哪里；
5. 修复后如何回归。

约束：
- 不要改 IOC，除非证据指向底层配置；
- 不要重写整个驱动；
- 根据 evidence 排列假设，不要跳到预设答案。
```

## 人工审核边界

AI 可以建议：

- 检查代码路径；
- 对比 datasheet 中的寄存器和公式；
- 生成测试脚本；
- 解释日志和寄存器；
- 提出最小修复。

AI 不应直接决定：

- 改硬件接线；
- 提高供电电压；
- 关闭保护性 gate；
- 改 Flash 地址；
- 改 SWD / BOOT 配置；
- 跳过失败项并标记 PASS。

## 证据优先级

| 优先级 | 证据 | 用途 |
|---|---|---|
| P0 | 自动化测试输出 | 判断哪个 gate 失败 |
| P0 | 原始串口日志 | 看实际命令响应 |
| P1 | raw sensor bytes | 区分总线问题和算法问题 |
| P1 | 寄存器快照 | 区分外设配置和应用层问题 |
| P2 | 逻辑分析仪截图 | 处理 I2C/UART 时序和偶发问题 |
| P2 | 代码 diff | 确认修复范围 |
