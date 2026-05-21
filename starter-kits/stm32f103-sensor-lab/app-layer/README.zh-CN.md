# 应用层接入契约

本目录定义 Liakia Starter-F103 Lab 的应用层边界。

用户负责：

- 使用 STM32CubeMX 创建 IOC；
- 生成 HAL 底层代码；
- 配置 USART1、I2C1、GPIO、SWD；
- 在 CubeMX 生成的工程里实现平台桥接。

Liakia 提供：

- 应用层入口函数；
- Shell 命令协议；
- BMP280 sensor gate；
- telemetry frame 和 CRC gate；
- known-bad case 的应用层实现；
- 测试脚本和 evidence 结构。

## 预期文件布局

用户可以把 Liakia 应用层复制到 CubeMX 生成工程中：

```text
Core/Inc/liakia_lab_app.h
Core/Inc/liakia_lab_platform.h
Core/Src/liakia_lab_app.c
Core/Src/liakia_lab_port_stm32f103.c   # 用户实现
```

第一版已经提供一个可改的 F103 HAL 桥接模板：

```text
app-layer/port-template/liakia_lab_port_stm32f103.c
```

用户可以复制到 `Core/Src/`，再按自己的 CubeMX 工程调整 `huart1`、`hi2c1` 和 LED 引脚。

## main.c 接入

```c
#include "liakia_lab_app.h"

int main(void)
{
  HAL_Init();
  SystemClock_Config();
  MX_GPIO_Init();
  MX_USART1_UART_Init();
  MX_I2C1_Init();

  LiakiaLab_Init();

  while (1)
  {
    LiakiaLab_Tick();
  }
}
```

## 平台桥接

用户需要把 HAL 对象桥接到 Liakia：

```c
LiakiaStatus LiakiaPlatform_I2cReadMem(uint8_t addr7, uint8_t reg, uint8_t *data, uint16_t len, uint32_t timeout_ms)
{
  return HAL_I2C_Mem_Read(&hi2c1, addr7 << 1, reg, I2C_MEMADD_SIZE_8BIT, data, len, timeout_ms) == HAL_OK
    ? LIAKIA_OK
    : LIAKIA_ERR;
}
```

## Shell 命令

第一版建议支持：

| 命令 | 作用 |
|---|---|
| `version` | 输出应用版本、MCU、build id |
| `led on/off` | 验证 GPIO |
| `sensor id` | 读取 BMP280 chip id |
| `sensor read` | 输出 BMP280 温度原始值、校准参数和补偿值 |
| `telemetry once` | 输出一帧带 CRC 的 telemetry |
| `diag i2c` | 输出 I2C scan 摘要 |
| `reset` | 软件复位，用于 reset recovery gate |

`config get/set/save` 属于后续 Case D：Flash persistence，不在当前基础 app 中实现，避免新手第一轮同时处理传感器和 Flash 两条问题线。

## Known-Bad 应用层原则

known-bad 代码只放在应用层，不修改 CubeMX 生成的底层驱动。这样用户可以清楚看到：

```text
底层工程是自己生成的；
问题来自应用层或配置接入；
Liakia 通过测试和证据链定位问题；
修复后同一套工程能回归 PASS。
```

known-bad 实验包入口见：

```text
known-bad-cases/
```

建议用户先接入基础 `liakia_lab_app.c`，确认 shell 和 sensor id 能跑，再进入某个 case 文件夹，导入其中故意改错的代码。每个 case 文件夹都包含练习指南和单独的答案解析。
