#include <stdint.h>
#include <string.h>

#define LIAKIA_CASE_D_MAGIC 0x4C4B4346u
#define LIAKIA_CASE_D_VERSION 1u

typedef struct {
  uint32_t magic;
  uint8_t version;
  uint16_t baud_divider;
  uint8_t flags;
  uint16_t crc;
} LiakiaCaseD_ConfigRecord;

static uint16_t Crc16Additive(const uint8_t *data, uint16_t len) {
  uint16_t crc = 0;

  for (uint16_t i = 0; i < len; ++i) {
    crc = (uint16_t)(crc + data[i]);
  }

  return crc;
}

int LiakiaCaseD_EncodeRecord(uint8_t *flash_page_shadow,
                             uint16_t flash_page_len,
                             uint16_t baud_divider,
                             uint8_t flags) {
  LiakiaCaseD_ConfigRecord rec;

  if (flash_page_len < sizeof(rec)) {
    return -1;
  }

  memset(&rec, 0, sizeof(rec));
  rec.magic = LIAKIA_CASE_D_MAGIC;
  rec.version = LIAKIA_CASE_D_VERSION;
  rec.baud_divider = baud_divider;
  rec.flags = flags;
  rec.crc = Crc16Additive((const uint8_t *)&rec, (uint16_t)(sizeof(rec) - sizeof(rec.crc)));

  for (uint16_t i = 0; i < sizeof(rec); ++i) {
    flash_page_shadow[i] &= ((const uint8_t *)&rec)[i];
  }

  return 0;
}

int LiakiaCaseD_DecodeRecord(const uint8_t *flash_page_shadow,
                             uint16_t flash_page_len,
                             uint16_t *baud_divider,
                             uint8_t *flags) {
  LiakiaCaseD_ConfigRecord rec;
  uint16_t crc;

  if (flash_page_len < sizeof(rec)) {
    return -1;
  }

  memcpy(&rec, flash_page_shadow, sizeof(rec));

  if (rec.magic != LIAKIA_CASE_D_MAGIC || rec.version != LIAKIA_CASE_D_VERSION) {
    return -2;
  }

  crc = Crc16Additive((const uint8_t *)&rec, (uint16_t)(sizeof(rec) - sizeof(rec.crc)));
  if (crc != rec.crc) {
    return -3;
  }

  *baud_divider = rec.baud_divider;
  *flags = rec.flags;
  return 0;
}
