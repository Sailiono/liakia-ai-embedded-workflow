# 故障练习包

这里是 STM32F103C8T6 Starter Lab 的故障注入练习。

每个 case 都是一个独立文件夹，里面包含故意改错的应用层或 port 层代码、练习指南和答案解析。建议按下面顺序做：先导入代码、烧录板子、采集证据，再让 AI 基于证据排查，最后才打开答案。

这个模块要让你真实体验：

```text
导入故障代码
编译并烧录 F103 板子
观察失败现象
运行 Liakia 脚本
采集证据包
让 AI 基于证据诊断
做最小修复
重新回归
最后再看答案解析
```

## Case 文件夹

| Case | 练习指南 | 需要导入的代码 | 难度 |
|---|---|---|---|
| Case A：BMP280 数据质量失败 | [case-a-bmp280-calibration/README.zh-CN.md](case-a-bmp280-calibration/README.zh-CN.md) | 完整替换 `liakia_lab_app.c` | 第一推荐 |
| Case B：I2C reset 后恢复失败 | [case-b-i2c-bus-stuck-reset/README.zh-CN.md](case-b-i2c-bus-stuck-reset/README.zh-CN.md) | 替换 `liakia_lab_port_stm32f103.c` | 硬件状态类 |
| Case C：Flash 配置持久化失败 | [case-c-flash-persistence-alignment/README.zh-CN.md](case-c-flash-persistence-alignment/README.zh-CN.md) | 配置持久化片段 | 状态持久化类 |
| Case D：UART DMA/IDLE 数据流失败 | [case-d-uart-dma-idle-race/README.zh-CN.md](case-d-uart-dma-idle-race/README.zh-CN.md) | DMA/IDLE 接收片段 | 高阶串口类 |

## 推荐顺序

先做 **Case A**。它使用基础 Starter Lab 的 BMP280 接线，不需要在第一版 IOC 之外额外启用 DMA、Flash 写入命令或复杂中断逻辑。

Case A 跑通后，再按目标能力选择：

- Case B：练 reset 后状态证据和 I2C 恢复推理；
- Case C：练状态持久化、reset 后验证、原始记录检查和回归；
- Case D：练高频串口帧、DMA/IDLE 和 CRC 类问题。

## 通用练习规则

1. 先让正常基础应用跑通；
2. 导入故障文件前，备份当前可工作的文件；
3. 一次只导入一个 case；
4. 除非 case 指南明确要求扩展 IOC，不要改 CubeMX 生成的 HAL 底层代码；
5. 第一次失败是预期现象，重点是证据包是否生成；
6. 把证据交给 AI，要求它只能基于日志、原始值和检查结果推理；
7. 先自己完成诊断，再打开 `ANSWER.zh-CN.md`。

## Runner 模式

大多数 case 使用同一套脚本形态：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\work\f103-liakia `
  -SkipBuild `
  -Elf Debug\f103-liakia.elf `
  -ComPort COM4 `
  -Case case-a `
  -ExpectedFailureGate data_quality `
  -AllowExpectedFailure
```

从证据目录生成 AI 诊断材料：

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\work\f103-liakia\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-a
```

每个 case 的具体导入路径和检查项名称，以 case 文件夹内的指南为准。
