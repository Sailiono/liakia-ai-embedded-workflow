#include "liakia_lab_app.h"

#include "liakia_lab_platform.h"

#include <stdio.h>
#include <string.h>

#define BMP280_ADDR_PRIMARY 0x76u
#define BMP280_ADDR_ALT 0x77u
#define BMP280_REG_ID 0xD0u
#define BMP280_EXPECTED_ID 0x58u

static char line_buf[96];
static uint8_t line_len;
static uint32_t last_telemetry_ms;

static void WriteLine(const char *s) {
  LiakiaPlatform_UartWrite(s, (uint16_t)strlen(s));
  LiakiaPlatform_UartWrite("\r\n", 2);
}

static uint16_t Crc16Ccitt(const uint8_t *data, uint16_t len) {
  uint16_t crc = 0xFFFFu;

  for (uint16_t i = 0; i < len; ++i) {
    crc ^= (uint16_t)data[i] << 8;
    for (uint8_t bit = 0; bit < 8; ++bit) {
      if ((crc & 0x8000u) != 0u) {
        crc = (uint16_t)((crc << 1) ^ 0x1021u);
      } else {
        crc <<= 1;
      }
    }
  }

  return crc;
}

static LiakiaStatus Bmp280ReadId(uint8_t *id, uint8_t *addr) {
  if (LiakiaPlatform_I2cReadMem(BMP280_ADDR_PRIMARY, BMP280_REG_ID, id, 1, 100) == LIAKIA_OK) {
    *addr = BMP280_ADDR_PRIMARY;
    return LIAKIA_OK;
  }

  if (LiakiaPlatform_I2cReadMem(BMP280_ADDR_ALT, BMP280_REG_ID, id, 1, 100) == LIAKIA_OK) {
    *addr = BMP280_ADDR_ALT;
    return LIAKIA_OK;
  }

  return LIAKIA_ERR;
}

static void CmdVersion(void) {
  WriteLine("Liakia Starter-F103 Lab");
  WriteLine("target=STM32F103C8T6 sensor=BMP280 shell=USART1");
}

static void CmdSensorId(void) {
  uint8_t id = 0;
  uint8_t addr = 0;
  char out[96];

  if (Bmp280ReadId(&id, &addr) != LIAKIA_OK) {
    WriteLine("SENSOR_ID FAIL reason=i2c_no_ack");
    return;
  }

  snprintf(out, sizeof(out), "SENSOR_ID addr=0x%02X id=0x%02X result=%s",
           addr, id, id == BMP280_EXPECTED_ID ? "PASS" : "FAIL");
  WriteLine(out);
}

static void CmdTelemetryOnce(void) {
  uint8_t id = 0;
  uint8_t addr = 0;
  uint8_t frame[8] = {'L', 'K', 1, 0, 0, 0, 0, 0};
  uint16_t crc;
  char out[96];

  if (Bmp280ReadId(&id, &addr) != LIAKIA_OK || id != BMP280_EXPECTED_ID) {
    WriteLine("TELEMETRY FAIL reason=sensor_id");
    return;
  }

  frame[3] = addr;
  frame[4] = id;
  frame[5] = (uint8_t)(LiakiaPlatform_Millis() & 0xFFu);
  crc = Crc16Ccitt(frame, 6);
  frame[6] = (uint8_t)(crc >> 8);
  frame[7] = (uint8_t)(crc & 0xFFu);

  snprintf(out, sizeof(out), "TELEMETRY LK %02X %02X %02X crc=%04X result=PASS",
           frame[3], frame[4], frame[5], crc);
  WriteLine(out);
}

static void CmdDiagI2c(void) {
  char out[96];
  int found = 0;

  for (uint8_t addr = 0x08; addr < 0x78; ++addr) {
    if (LiakiaPlatform_I2cProbe(addr, 20) == LIAKIA_OK) {
      snprintf(out, sizeof(out), "I2C_SCAN found=0x%02X", addr);
      WriteLine(out);
      ++found;
    }
  }

  snprintf(out, sizeof(out), "I2C_SCAN result=%s count=%d", found > 0 ? "PASS" : "FAIL", found);
  WriteLine(out);
}

static void Dispatch(const char *cmd) {
  if (strcmp(cmd, "version") == 0) {
    CmdVersion();
  } else if (strcmp(cmd, "led on") == 0) {
    LiakiaPlatform_LedSet(true);
    WriteLine("LED PASS state=on");
  } else if (strcmp(cmd, "led off") == 0) {
    LiakiaPlatform_LedSet(false);
    WriteLine("LED PASS state=off");
  } else if (strcmp(cmd, "sensor id") == 0) {
    CmdSensorId();
  } else if (strcmp(cmd, "telemetry once") == 0) {
    CmdTelemetryOnce();
  } else if (strcmp(cmd, "diag i2c") == 0) {
    CmdDiagI2c();
  } else if (strcmp(cmd, "reset") == 0) {
    WriteLine("RESET requested");
    LiakiaPlatform_SystemReset();
  } else {
    WriteLine("ERR unknown_command");
  }
}

void LiakiaLab_Init(void) {
  line_len = 0;
  last_telemetry_ms = LiakiaPlatform_Millis();
  WriteLine("Liakia Starter-F103 ready");
  WriteLine("type: version | sensor id | diag i2c | telemetry once");
}

void LiakiaLab_Tick(void) {
  uint32_t now = LiakiaPlatform_Millis();

  if ((now - last_telemetry_ms) >= 5000u) {
    last_telemetry_ms = now;
    CmdTelemetryOnce();
  }
}

void LiakiaLab_OnUartRx(uint8_t byte) {
  if (byte == '\r' || byte == '\n') {
    if (line_len > 0u) {
      line_buf[line_len] = '\0';
      Dispatch(line_buf);
      line_len = 0;
    }
    return;
  }

  if (line_len < sizeof(line_buf) - 1u) {
    line_buf[line_len++] = (char)byte;
  } else {
    line_len = 0;
    WriteLine("ERR line_overflow");
  }
}
