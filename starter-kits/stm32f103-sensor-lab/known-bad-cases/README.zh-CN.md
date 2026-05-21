# Known-Bad 实验包

这里是 STM32F103C8T6 Starter Lab 的故障注入实验包。

每个 case 都是一个独立文件夹。文件夹里包含故意改错的应用层或 port 层代码、练习指南，以及单独的答案解析。建议先导入代码、烧录板子、采集 evidence、让 AI 基于证据排查，再打开答案文件。

这个模块要让用户真实体验：

```text
导入故意改错的应用层代码
编译并烧录 F103 板子
观察失败现象
运行 Liakia gates
采集 evidence
让 AI 基于 evidence 诊断
做最小修复
重新回归
最后再看答案解析
```

## Case 文件夹

| Case | 练习指南 | 需要导入的代码 | 难度 |
|---|---|---|---|
| Case B：BMP280 数据质量失败 | [case-b-bmp280-calibration/README.zh-CN.md](case-b-bmp280-calibration/README.zh-CN.md) | 完整替换 `liakia_lab_app.c` | 第一推荐 case |
| Case A：I2C reset recovery 失败 | [case-a-i2c-bus-stuck-reset/README.zh-CN.md](case-a-i2c-bus-stuck-reset/README.zh-CN.md) | 替换 `liakia_lab_port_stm32f103.c` | 硬件状态 case |
| Case C：UART DMA/IDLE stream 失败 | [case-c-uart-dma-idle-race/README.zh-CN.md](case-c-uart-dma-idle-race/README.zh-CN.md) | DMA/IDLE 接收片段 | 高级串口 case |
| Case D：Flash persistence 失败 | [case-d-flash-persistence-alignment/README.zh-CN.md](case-d-flash-persistence-alignment/README.zh-CN.md) | 配置持久化片段 | 高级持久化 case |

## 推荐顺序

先做 **Case B**。它使用基础 Starter Lab 的 BMP280 接线，不需要在第一版 IOC 之外额外启用 DMA、Flash 写入命令或复杂中断逻辑。

Case B 跑通后，再按目标能力选择：

- Case A：练 reset-state evidence 和 I2C recovery 推理；
- Case C：练高频串口帧、DMA/IDLE 和 CRC 类问题；
- Case D：练状态持久化、reset 后验证、raw record 检查和回归 gate。

## 通用练习规则

1. 先让正常基础 app 跑通；
2. 导入 known-bad 文件前，备份当前可工作的文件；
3. 一次只导入一个 case；
4. 除非 case 指南明确要求扩展 IOC，不要改 CubeMX 生成的 HAL 底层代码；
5. 第一次失败是预期现象，重点是 evidence package 是否生成；
6. 把 evidence 交给 AI，要求它只能基于日志、raw value 和 gate result 推理；
7. 先自己完成诊断，再打开 `ANSWER.zh-CN.md`。

## Runner 模式

大多数 case 使用同一套 runner 形态：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-b `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

从 evidence 目录生成 AI 诊断材料：

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-b
```

每个 case 的具体导入路径和 gate 名称，以 case 文件夹内的指南为准。
