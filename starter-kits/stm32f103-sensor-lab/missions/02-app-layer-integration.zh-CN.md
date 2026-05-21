# Mission 02：接入 Liakia 应用层

这个任务的重点是让用户把 Liakia 应用层接进自己生成的 HAL 工程。底层工程仍然由用户维护，Liakia 只占用清晰的应用层边界。

## 复制文件

建议复制：

```text
starter-kits/stm32f103-sensor-lab/app-layer/include/liakia_lab_app.h
starter-kits/stm32f103-sensor-lab/app-layer/include/liakia_lab_platform.h
starter-kits/stm32f103-sensor-lab/app-layer/src/liakia_lab_app.c
```

放入用户工程：

```text
Core/Inc/liakia_lab_app.h
Core/Inc/liakia_lab_platform.h
Core/Src/liakia_lab_app.c
```

## 用户需要实现的 port

新增：

```text
Core/Src/liakia_lab_port_stm32f103.c
```

它实现：

```c
uint32_t LiakiaPlatform_Millis(void);
void LiakiaPlatform_UartWrite(const char *data, uint16_t len);
void LiakiaPlatform_LedSet(bool on);
void LiakiaPlatform_SystemReset(void);
LiakiaStatus LiakiaPlatform_I2cReadMem(...);
LiakiaStatus LiakiaPlatform_I2cWriteMem(...);
LiakiaStatus LiakiaPlatform_I2cProbe(...);
LiakiaStatus LiakiaPlatform_I2cBusRecover(void);
LiakiaStatus LiakiaPlatform_ConfigLoad(void *data, uint16_t len);
LiakiaStatus LiakiaPlatform_ConfigSave(const void *data, uint16_t len);
```

第一版可以先把 `ConfigLoad/ConfigSave` 返回 `LIAKIA_ERR`，等 Mission 04/05 再接入 Flash persistence case。

## main.c 接入点

在 include 区域：

```c
#include "liakia_lab_app.h"
```

在初始化后：

```c
LiakiaLab_Init();
```

在主循环：

```c
while (1)
{
  LiakiaLab_Tick();
}
```

## 串口接收

第一版可以用中断接收单字节：

```c
uint8_t uart_rx_byte;

HAL_UART_Receive_IT(&huart1, &uart_rx_byte, 1);

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
  if (huart->Instance == USART1) {
    LiakiaLab_OnUartRx(uart_rx_byte);
    HAL_UART_Receive_IT(&huart1, &uart_rx_byte, 1);
  }
}
```

## 通过标准

串口发送：

```text
version
```

预期：

```text
Liakia Starter-F103 Lab
target=STM32F103C8T6 sensor=BMP280 shell=USART1
```

发送：

```text
led on
led off
```

预期：

```text
LED PASS state=on
LED PASS state=off
```
