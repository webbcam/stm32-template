/*
 * Core exception handlers. These override the weak aliases in the startup
 * file, which otherwise all point at Default_Handler (an infinite loop).
 *
 * Compiled directly into the executable, not a static library: the startup
 * file already provides weak definitions, so the linker would never pull a
 * strong one out of an archive.
 */
#include "mcu.h"

/* Drives HAL_GetTick()/HAL_Delay(); HAL_Init() configures SysTick at 1kHz. */
void SysTick_Handler(void)
{
    HAL_IncTick();
}
