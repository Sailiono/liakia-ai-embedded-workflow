# Mission 05：修复与回归

这个任务把故障排查闭环收口：修复不是终点，回归证据才是终点。

请在完成以下步骤后再做这个 mission：

1. 导入一个故障练习；
2. 复现失败检查；
3. 生成证据包；
4. 让 AI 基于证据诊断；
5. 阅读该 case 的答案解析并核对自己的判断。

## 修复原则

修复必须满足：

- 修改范围最小；
- 能解释为什么改；
- 和证据中的失败现象对应；
- 避免无关 IOC、HAL、clock-tree 修改；
- 重新运行同一组检查；
- 生成新的证据包。

## 按 case 修复

每个故障练习文件夹都有自己的答案文件：

```text
known-bad-cases/<case-folder>/ANSWER.zh-CN.md
```

用答案文件核对你的诊断，然后只做和证据匹配的最小修改。不要把一个局部修复扩大成驱动重写。

## 回归命令

可以手工执行：

```text
version
diag i2c
sensor id
sensor read
telemetry once
reset
version
sensor id
```

也可以使用当前自动化脚本封装为：

```powershell
starter-kits/stm32f103-sensor-lab/tools/run_starter_f103.ps1 `
  -ProjectRoot C:\path\to\your\cubemx-project `
  -Elf Debug\app.elf `
  -ComPort COMx `
  -Case case-a
```

## PASS 标准

```text
build PASS
flash PASS
shell PASS
i2c scan PASS
sensor id PASS
data quality PASS
telemetry CRC PASS
reset recovery PASS 或明确 skip reason
manifest GENERATED
```

## 交接摘要模板

修复完成后，应输出一段简短交接摘要：

```text
Issue:
  哪个检查项失败，原始输出是什么。

Evidence:
  哪些日志、原始值、寄存器或内存证据支持诊断。

Fix:
  修改了哪个文件、哪一小段代码，以及为什么这是最小有效修复。

Regression:
  重新运行了哪些检查项，PASS 标准是什么。
```
