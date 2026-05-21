#ifndef LIAKIA_LAB_APP_H
#define LIAKIA_LAB_APP_H

#include <stdint.h>

void LiakiaLab_Init(void);
void LiakiaLab_Tick(void);
void LiakiaLab_OnUartRx(uint8_t byte);

#endif
