#ifndef LIAKIA_BMP280_CASE_B_H
#define LIAKIA_BMP280_CASE_B_H

#include <stdint.h>

#include "liakia_lab_platform.h"

typedef struct {
  uint16_t dig_t1;
  int16_t dig_t2;
  int16_t dig_t3;
} LiakiaBmp280TempCalib;

typedef struct {
  int32_t raw_temp;
  int32_t temperature_x100;
} LiakiaBmp280TempSample;

LiakiaStatus LiakiaBmp280CaseB_ReadId(uint8_t *id);
LiakiaStatus LiakiaBmp280CaseB_ReadTemperature(LiakiaBmp280TempSample *sample);

#endif
