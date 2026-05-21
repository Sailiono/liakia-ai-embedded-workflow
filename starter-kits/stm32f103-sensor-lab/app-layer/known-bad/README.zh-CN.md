# Known-Bad 应用层

这里放的是可以接入用户自生成 HAL 工程的应用层片段，不包含 IOC、不包含 HAL 初始化代码、不包含完整可烧录工程。

用户流程：

```text
1. 自己用 CubeMX 生成 STM32F103C8T6 工程
2. 接入 app-layer/include 和 app-layer/src
3. 选择一个 known-bad case 的应用层文件
4. 编译、烧录、运行 Liakia gates
5. 根据 evidence 定位问题
6. 只在应用层或 IOC 配置中做最小修复
```

## 第一版 known-bad case

| Case | 文件 | 预期现象 |
|---|---|---|
| Case B：BMP280 calibration / compensation issue | [case_b_bmp280_calibration/liakia_bmp280_case_b.c](case_b_bmp280_calibration/liakia_bmp280_case_b.c) | `sensor id PASS`，但 `sensor read` 或 data-quality gate FAIL |

## 推荐接入方式

为了让新手路径最短，第一版推荐按这里的练习卡片操作：

```text
../../known-bad-cases/case-b-bmp280-calibration.zh-CN.md
```

该页面会告诉你如何注入 bug，但不会一开始解释根因。`case_b_bmp280_calibration/` 里的文件用于展示这个问题的独立应用层片段，便于代码 review 和 AI 诊断时引用；它不是完整 CubeMX 工程。

这个 case 不是 I2C 地址写错。它的设计目标是模拟工程中更麻烦的情况：

```text
总线能通
chip id 正确
raw bytes 能读
但补偿后的温度不可信
```

这类问题能展示 Liakia 的核心价值：协议层和数据质量 gate 能把“看起来能跑”的代码拦下来，并把 AI 分析限定在有证据的范围内。

建议先跑 gate 并生成诊断材料，再读答案解析。
