# Troubleshooting

## ST-LINK Cannot Connect

Check first:

- shared GND;
- SWDIO / SWCLK swapped;
- BOOT0 low;
- Serial Wire not disabled in IOC;
- SWD frequency not too high;
- NRST connected when the board is unstable.

Useful evidence:

```text
STM32CubeProgrammer connect transcript
target voltage
device id
connect mode
SWD frequency
```

## Garbled Serial Output

Check first:

- USB-TTL adapter is 3.3 V logic;
- PA9/PA10 are crossed correctly;
- baud rate is 115200;
- USART1 is initialized;
- GND is shared.

Do not start by blaming the application layer.

## Shell Does Not Respond But Flash Succeeds

Common causes:

- `LiakiaLab_Init()` was not called;
- `LiakiaLab_Tick()` was not called;
- UART RX interrupt was not enabled;
- `HAL_UART_RxCpltCallback` does not restart reception;
- UART write function does not call `HAL_UART_Transmit`.

## I2C Scan Finds No Device

Check first:

- BMP280 powered at 3.3 V;
- SCL/SDA not swapped;
- PB6/PB7 configured as I2C1;
- pull-ups present;
- I2C speed not too high;
- address is `0x76` or `0x77`.

## `sensor id` Passes But `sensor read` Fails

This is usually not a wiring problem. Check:

- BMP280 power mode;
- wait time after forced measurement;
- calibration byte count;
- signed / unsigned conversion;
- little-endian assembly;
- compensation formula.

## Failure After Reset

Check:

- reset reason;
- I2C bus recovery;
- sensor reconfiguration after reset;
- config reload from Flash;
- UART receive restart.

## Evidence Is Too Weak For Diagnosis

If the AI output is vague, the evidence is probably incomplete. At minimum, collect:

```text
version
diag i2c
sensor id
sensor read
telemetry once
before/after reset comparison
relevant code snippets
```
