# Bill Of Materials

## Recommended Base Kit

| Item | Recommendation | Notes |
|---|---|---|
| MCU board | STM32F103C8T6 Blue Pill compatible board | Prefer a board with clear chip marking and a stable 3.3 V regulator |
| Debug probe | ST-LINK/V2 or compatible probe | Used for SWD flash and read-only register probing |
| Serial adapter | USB-TTL, 3.3 V logic level | Do not connect 5 V TTL directly to F103 pins |
| Sensor | BMP280 I2C module | Prefer a module with 3.3 V supply support and I2C pull-ups |
| Resistors | 4.7k x2 | SDA/SCL pull-ups if the module does not already include them |
| Wires | Jumper wires | SWD, UART, I2C, and common ground |
| Optional tool | 8-channel logic analyzer | Useful for I2C / UART timing and advanced fault cases |

## Hardware Not Recommended For The First Lab

| Hardware | Why |
|---|---|
| DHT11 / DHT22 | Useful for timing exercises, but weak for register-level evidence and automated gates |
| DS18B20 | Good temperature sensor, but less connected to MCU peripheral configuration |
| OLED display | Visually attractive, but adds another I2C device and can distract the first bringup |
| Multiple sensors at once | Too much ambiguity for the first lab; close one sensor loop first |

## Selection Notes

- Keep the first setup boring: one MCU, one probe, one UART, one sensor.
- Use 3.3 V logic throughout.
- If the BMP280 module has selectable address pins, record whether it is `0x76` or `0x77` in the evidence package.
- If a board clone behaves differently, document the board markings and any jumper changes in `00_manifest.json`.
