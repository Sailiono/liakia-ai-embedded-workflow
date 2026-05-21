#include "liakia_bmp280_case_b.h"

#define BMP280_ADDR 0x76u
#define BMP280_REG_ID 0xD0u
#define BMP280_REG_CALIB_T1 0x88u
#define BMP280_REG_CTRL_MEAS 0xF4u
#define BMP280_REG_TEMP_MSB 0xFAu

static int32_t t_fine;

static uint16_t U16(const uint8_t *p) {
  return (uint16_t)(((uint16_t)p[1] << 8) | p[0]);
}

static int16_t S16(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[0] << 8) | p[1]);
}

LiakiaStatus LiakiaBmp280CaseB_ReadId(uint8_t *id) {
  return LiakiaPlatform_I2cReadMem(BMP280_ADDR, BMP280_REG_ID, id, 1, 100);
}

static LiakiaStatus ReadTempCalibration(LiakiaBmp280TempCalib *calib) {
  uint8_t raw[6];

  if (LiakiaPlatform_I2cReadMem(BMP280_ADDR, BMP280_REG_CALIB_T1, raw, sizeof(raw), 100) != LIAKIA_OK) {
    return LIAKIA_ERR;
  }

  calib->dig_t1 = U16(&raw[0]);
  calib->dig_t2 = S16(&raw[2]);
  calib->dig_t3 = S16(&raw[4]);
  return LIAKIA_OK;
}

static LiakiaStatus ForceMeasurement(void) {
  const uint8_t ctrl = 0x25u;
  return LiakiaPlatform_I2cWriteMem(BMP280_ADDR, BMP280_REG_CTRL_MEAS, &ctrl, 1, 100);
}

static LiakiaStatus ReadRawTemperature(int32_t *raw_temp) {
  uint8_t raw[3];

  if (LiakiaPlatform_I2cReadMem(BMP280_ADDR, BMP280_REG_TEMP_MSB, raw, sizeof(raw), 100) != LIAKIA_OK) {
    return LIAKIA_ERR;
  }

  *raw_temp = ((int32_t)raw[0] << 12) | ((int32_t)raw[1] << 4) | ((int32_t)raw[2] >> 4);
  return LIAKIA_OK;
}

static int32_t CompensateTemperatureX100(int32_t adc_t, const LiakiaBmp280TempCalib *calib) {
  int32_t var1;
  int32_t var2;
  int32_t temp;

  var1 = ((((adc_t >> 3) - ((int32_t)calib->dig_t1 << 1))) * ((int32_t)calib->dig_t2)) >> 11;
  var2 = (((((adc_t >> 4) - ((int32_t)calib->dig_t1)) *
            ((adc_t >> 4) - ((int32_t)calib->dig_t1))) >> 12) *
          ((int32_t)calib->dig_t3)) >> 14;
  t_fine = var1 + var2;
  temp = (t_fine * 5 + 128) >> 8;
  return temp;
}

LiakiaStatus LiakiaBmp280CaseB_ReadTemperature(LiakiaBmp280TempSample *sample) {
  LiakiaBmp280TempCalib calib;

  if (ReadTempCalibration(&calib) != LIAKIA_OK) {
    return LIAKIA_ERR;
  }

  if (ForceMeasurement() != LIAKIA_OK) {
    return LIAKIA_ERR;
  }

  if (ReadRawTemperature(&sample->raw_temp) != LIAKIA_OK) {
    return LIAKIA_ERR;
  }

  sample->temperature_x100 = CompensateTemperatureX100(sample->raw_temp, &calib);
  return LIAKIA_OK;
}
