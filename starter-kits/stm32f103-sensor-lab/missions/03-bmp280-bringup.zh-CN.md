# Mission 03：BMP280 Bringup

这个任务验证 I2C 总线、BMP280 chip id、基础 telemetry 和数据质量 gate。

## 目标

```text
I2C1 可访问 BMP280
chip id = 0x58
telemetry once 能输出带 CRC 的帧摘要
```

## 操作步骤

1. 确认 BMP280 接到 PB6/PB7；
2. 确认 SDA/SCL 上拉到 3.3V；
3. 烧录基础 app-layer；
4. 打开串口；
5. 依次输入命令。

## 命令

```text
diag i2c
sensor id
telemetry once
```

预期输出：

```text
I2C_SCAN found=0x76
I2C_SCAN result=PASS count=1
SENSOR_ID addr=0x76 id=0x58 result=PASS
TELEMETRY LK 76 58 xx crc=xxxx result=PASS
```

如果你的 BMP280 模块地址是 0x77，应记录在 evidence 中。基础 app-layer 会尝试 0x76 和 0x77，这样在导入任何 known-bad case 前，地址差异已经有明确证据。

## 通过标准

```text
i2c scan PASS
sensor id PASS
telemetry frame emitted
crc field present
```

## 失败证据

如果失败，不要直接改代码。先收集：

```text
串口命令输出
I2C scan 结果
SDA/SCL idle 电平
GPIOB_CRL / GPIOB_IDR 摘要
RCC_APB1ENR I2C1EN 状态
```

这些证据会在 Mission 04/05 中作为 AI 诊断输入。
