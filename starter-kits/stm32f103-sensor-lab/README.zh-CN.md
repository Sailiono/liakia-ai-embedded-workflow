# Liakia Starter-F103 传感器实验

这是 Liakia 面向新手和潜在客户的真实动手入口。

如果你要直接开始做实验，先读：

```text
quick-start.zh-CN.md
```

本目录包含完成 F103 实验需要的硬件、接线、IOC、应用层、known-bad、测试 gate、诊断和 evidence 文档；不需要回到仓库其他目录才能完成这个 Lab。

它不替代 dpiny-RTK 工程案例，而是和专业入口并列：

| 入口 | 面向对象 | 作用 |
|---|---|---|
| Starter-F103 Sensor Lab | 新手、评估者、初中级工程师 | 用低成本 STM32F103C8T6 搭一个可真实调试的硬件台架 |
| dpiny-RTK Engineering Case | 嵌入式工程师 | 查看真实 STM32F407 + RTK 项目的交付证据链 |
| Workflow Template | 团队负责人、顾问、交付方 | 把 build / flash / test / evidence 闭环迁移到自己的 STM32 项目 |

## 这个 Lab 的核心思路

底层工程由用户自己完成：

```text
用户创建 STM32CubeMX IOC
用户生成 HAL / 启动代码 / 外设初始化
用户把 Liakia 提供的应用层接入进去
用户烧录 known-bad 应用层
用户运行测试并观察失败
用户使用 Liakia 的证据链思路定位和修复问题
```

Liakia 不直接给一个完整可烧录工程，原因是：如果一切都打包好了，用户只是在运行别人的结果，参与感和迁移价值都不强。

本 Lab 给的是：

- 硬件搭建路线；
- IOC 配置提示，避免偏离轨道；
- 应用层接入契约；
- 已知存在问题的应用层示例；
- 自动化测试和证据包结构；
- 故障复盘任务。

## 推荐硬件

| 物料 | 作用 |
|---|---|
| STM32F103C8T6 Blue Pill 类开发板 | 主控板 |
| ST-LINK 兼容调试器 | SWD 烧录和寄存器读取 |
| USB-TTL 模块 | UART Shell 和 telemetry |
| BMP280 模块 | I2C 传感器，覆盖 chip id、校准参数和补偿算法 |
| 4.7k 上拉电阻 | I2C 上拉，部分模块自带可省略 |
| 杜邦线 | SWD、UART、I2C、GND 共地 |

## 学习路径

```text
焊接排针
  -> SWD / UART / I2C 接线
  -> CubeMX 新建 STM32F103C8T6 工程
  -> 配置 SYS / RCC / USART1 / I2C1 / GPIO
  -> 生成 HAL 工程
  -> 接入 Liakia 应用层
  -> 编译
  -> 烧录
  -> 运行 Shell / Sensor / Protocol gates
  -> 触发 known-bad 故障
  -> 采集日志和寄存器证据
  -> AI 辅助分析
  -> 修复应用层
  -> 回归 PASS
  -> 生成 evidence package
```

## 为什么选择 BMP280

BMP280 比简单温度模块更适合做故障训练：

- 有 I2C 总线；
- 有固定 chip id；
- 有校准参数区；
- 有 signed / unsigned 和 little-endian 处理；
- 有温度补偿算法，后续可扩展气压补偿；
- 有 reset 后重新初始化问题；
- 容易做数据质量 gate。

这能设计出比“地址写错”更接近真实工程的故障。

## Lab 文件

| 文件 | 内容 |
|---|---|
| [quick-start.zh-CN.md](quick-start.zh-CN.md) | 从硬件、IOC、应用层、known-bad 到回归 PASS 的完整中文快速上手 |
| [quick-start.md](quick-start.md) | English quick start for the same hands-on lab |
| [bom.zh-CN.md](bom.zh-CN.md) | 物料清单和选型说明 |
| [wiring.zh-CN.md](wiring.zh-CN.md) | 焊线和接线说明 |
| [cubemx-ioc-guide.zh-CN.md](cubemx-ioc-guide.zh-CN.md) | IOC 配置检查点 |
| [missions/README.zh-CN.md](missions/README.zh-CN.md) | 任务剧情 |
| [known-bad-cases/README.zh-CN.md](known-bad-cases/README.zh-CN.md) | 故障设计 |
| [app-layer/README.zh-CN.md](app-layer/README.zh-CN.md) | 应用层接入契约 |
| [app-layer/port-template/](app-layer/port-template/) | CubeMX HAL 工程的 F103 平台桥接模板 |
| [test-gates.zh-CN.md](test-gates.zh-CN.md) | 测试 gate 和 PASS/FAIL 标准 |
| [diagnosis-playbook.zh-CN.md](diagnosis-playbook.zh-CN.md) | AI 诊断输入和输出格式 |
| [evidence-template/README.zh-CN.md](evidence-template/README.zh-CN.md) | 证据包模板和 Case B 样例 |
| [troubleshooting.zh-CN.md](troubleshooting.zh-CN.md) | 常见问题排查 |
| [tools/](tools/) | Starter runner、F103 register probe、诊断 prompt 生成脚本 |
| [future-automation.zh-CN.md](future-automation.zh-CN.md) | 后续增强计划 |

## 当前脚本入口

完整 baseline：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -BuildCommand "cmake --build --preset Debug" `
  -Elf build/Debug/app.elf `
  -ComPort COM4 `
  -Case case-b
```

如果暂时不想烧录，必须显式加 `-SkipFlash`。没有 `-Elf` 时 runner 会失败，避免误测旧固件。

只生成 AI 诊断 prompt：

```powershell
starter-kits/stm32f103-sensor-lab/tools/diagnose_starter_f103.ps1 `
  -EvidenceDir C:\path\to\your\cubemx-project\evidence-out\starter-f103-YYYYMMDD-HHMMSS `
  -Case case-b
```

只读寄存器探查：

```powershell
starter-kits/stm32f103-sensor-lab/tools/register_probe_f103.ps1 `
  -Target rcc,gpio,usart,i2c,flash,fault `
  -OutputJson evidence-out/register_probe_f103_summary.json
```
