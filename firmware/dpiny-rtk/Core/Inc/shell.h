/**
 * @file    shell.h
 * @author  Clark Cui
 * @brief   Interactive shell parser with command table
 * @date    2026-05-09
 */
#ifndef __SHELL_H
#define __SHELL_H

#include "main.h"
#include <stdarg.h>

void Shell_Init(void);
void Shell_ProcessChar(uint8_t ch);
void Shell_Printf(const char *fmt, ...);

#endif /* __SHELL_H */
