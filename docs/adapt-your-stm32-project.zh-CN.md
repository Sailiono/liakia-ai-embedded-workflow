# 如何把你的 STM32 项目接入 Liakia

Liakia 不绑定 dpiny-RTK 固件。它的目标是把你已有的 STM32 工程接入一套可重复执行、失败也能留痕的交付流程：

```text
编译 -> 烧录 -> 串口测试 -> 协议检查 -> 寄存器快照 -> 证据包
```

这份文档说明：另一个 STM32 固件项目要接入同类流程，需要准备什么、先做哪一步、最后应该交付什么。

## 1. 项目方需要提供什么

第一次接入时，通常需要准备：

| 项目 | 用途 |
|---|---|
| 固件仓库或工程导出 | 作为编译和测试接入点 |
| MCU 与板卡信息 | 确认烧录目标、内存布局和寄存器快照范围 |
| 现有编译命令 | CMake、Make、CubeIDE headless 或其他可复现构建入口 |
| 烧录方式 | ST-LINK、J-Link、DFU、bootloader 或厂商 CLI |
| 串口接口 | Shell 口、调试口、协议输出口和波特率 |
| 基础测试期望 | 命令、关键词、协议帧和错误边界 |
| 硬件风险说明 | 电源、复位、boot pin、隔离和安全边界 |
| 交付期望 | 每次运行后希望沉淀哪些证据 |

## 2. 定义项目适配文件

Liakia 用一个项目适配文件描述差异。这样工作流本身保持通用，项目相关路径、命令和端口都显式写出来，后续交接时也更容易复查。

示例：

```json
{
  "project": {
    "name": "customer-stm32-board",
    "root": "../customer-firmware",
    "elf": "build/Debug/customer.elf"
  },
  "build": {
    "command": "ninja",
    "working_dir": "build/Debug"
  },
  "flash": {
    "tool": "STM32_Programmer_CLI",
    "connect": "port=SWD freq=4000",
    "verify": true,
    "reset": true
  },
  "serial": {
    "shell_port": "COM4",
    "rtcm_port": "COM6",
    "baudrate": 115200
  },
  "tests": [
    {
      "name": "shell",
      "script": "tools/test_shell.ps1",
      "args": {
        "Port": "COM4",
        "OutputJson": "evidence-out/shell_summary.json"
      }
    }
  ],
  "register_probe": {
    "enabled": true,
    "targets": ["rcc", "gpio", "usart", "fault"]
  }
}
```

## 3. 先接入编译和烧录

第一阶段先把编译命令和烧录记录固定下来。不要一开始就追求覆盖所有测试项。

```powershell
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage build
workflow-template/run_workflow.ps1 -Adapter workflow-template/project-adapter.json -Stage flash
```

建议保留的证据：

- 工具链版本；
- 编译命令与工作目录；
- 编译 warning / error；
- ELF / HEX / BIN 大小；
- 固件产物 SHA256；
- flash verify log；
- reset 方式。

## 4. 添加串口检查

先从少量命令开始，证明固件活着、能响应、能读配置、能正确处理错误输入。

常见检查项：

| 检查项 | 示例 |
|---|---|
| 身份识别 | `version` 返回项目名和固件版本 |
| 健康状态 | `status` 返回任务、uptime 或接口状态 |
| 配置读取 | `config` 返回当前持久化配置 |
| 输入校验 | 无效命令被拒绝，Shell 不崩溃 |
| reset 后恢复 | 软件复位后 Shell 仍能响应 |

关键规则：测试脚本必须用退出码明确表示成功或失败，不能只把日志打印出来交给人肉判断。

## 5. 添加协议或业务检查

dpiny-RTK 的协议检查是 RTCM CRC 校验。其他项目可以换成自己的业务检查：

| 项目类型 | 可选检查项 |
|---|---|
| 传感器网关 | 帧数量、CRC、时间戳单调性 |
| 电机控制器 | 命令响应、fault 状态、电流限制状态 |
| 工业 I/O | Modbus request/response、输入状态矩阵 |
| 飞控外设 | telemetry packet parse、heartbeat timeout |
| GNSS / RTK | RTCM 帧解析、CRC、消息类型覆盖 |

协议检查应该在无帧、CRC 错误、必要消息缺失或数值不可能时失败。

## 6. 添加寄存器证据

寄存器快照不是替代调试，而是在测试失败时留下底层证据，帮助工程师判断问题更可能出在时钟、GPIO、外设状态、复位原因还是协议层。

第一批常用目标：

- CPU fault 状态；
- reset flags；
- RCC clock enable registers；
- GPIO mode 和 alternate function registers；
- USART / SPI / I2C control 和 status registers；
- 如果项目有 USB CDC，则加入 USB state registers。

公开模板只做只读采集。任何寄存器写入都应视为高风险操作，需要人工批准。

## 7. 生成证据包

目标是让另一个工程师或管理者不用翻聊天记录，也能审查本次运行。

建议输出：

```text
evidence-out/
  manifest.json
  logs/
    environment.log
    build.log
    flash.log
    shell.log
    protocol.log
    register_probe.log
  summaries/
    shell_summary.json
    protocol_summary.json
    register_probe_summary.json
  handoff_report.md
```

即使测试失败，也应该生成 `manifest.json`。失败证据往往比干净的 PASS 更有价值，因为它能说明问题发生在哪一步、输入是什么、后续该查哪里。

## 8. 典型一周试点范围

一个现有 STM32 项目的第一轮接入可以这样规划：

| 天数 | 交付物 |
|---|---|
| 第 1 天 | 编译和烧录命令可复现 |
| 第 2 天 | Shell 或串口 smoke test 接入 |
| 第 3 天 | 一个协议或业务检查接入 |
| 第 4 天 | 只读寄存器快照和失败证据格式接入 |
| 第 5 天 | 基线脚本、运行清单、交接报告，与研发团队复核 |

一周试点默认不包含：

- PCB 重新设计；
- EMC / ESD 认证；
- 安全认证；
- 量产测试治具设计；
- 替换客户现有固件框架或 IDE。

## 9. 人工复核边界

Liakia 应该把最终工程判断权留给人。

以下内容必须人工复核：

- flash layout 或 boot 配置修改；
- watchdog 策略修改；
- 安全相关行为；
- 寄存器写入；
- 电源、隔离或外部负载假设；
- 证据和根因判断互相冲突。

## 10. 接入结果

接入完成后，团队应该能通过一条命令得到：

- 编译结果；
- 烧录结果；
- 串口测试结果；
- 协议检查结果；
- 必要时的寄存器证据；
- 运行清单和交接报告；
- 给下一步工程决策使用的明确 PASS/FAIL 边界。
