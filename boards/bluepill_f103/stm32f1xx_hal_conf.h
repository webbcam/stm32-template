/*
 * Board-owned HAL config for bluepill (STM32F103C8T6).
 * Enable additional HAL_xxx_MODULE_ENABLED lines as the app uses more
 * peripherals. Based on ST's stm32f1xx_hal_conf_template.h.
 */
#ifndef STM32F1xx_HAL_CONF_H
#define STM32F1xx_HAL_CONF_H

#define HAL_MODULE_ENABLED
#define HAL_CORTEX_MODULE_ENABLED
#define HAL_GPIO_MODULE_ENABLED
#define HAL_EXTI_MODULE_ENABLED
#define HAL_RCC_MODULE_ENABLED
#define HAL_FLASH_MODULE_ENABLED
#define HAL_PWR_MODULE_ENABLED
#define HAL_DMA_MODULE_ENABLED

#if !defined(HSE_VALUE)
#define HSE_VALUE 8000000U /* bluepill onboard crystal */
#endif
#define HSE_STARTUP_TIMEOUT 100U

#if !defined(HSI_VALUE)
#define HSI_VALUE 8000000U
#endif

#define LSI_VALUE 40000U
#define LSE_VALUE 32768U
#define LSE_STARTUP_TIMEOUT 5000U

#define VDD_VALUE 3300U
#define TICK_INT_PRIORITY 0x0FU
#define USE_RTOS 0U
#define PREFETCH_ENABLE 1U

#ifdef HAL_RCC_MODULE_ENABLED
#include "stm32f1xx_hal_rcc.h"
#endif
#ifdef HAL_GPIO_MODULE_ENABLED
#include "stm32f1xx_hal_gpio.h"
#endif
#ifdef HAL_EXTI_MODULE_ENABLED
#include "stm32f1xx_hal_exti.h"
#endif
#ifdef HAL_DMA_MODULE_ENABLED
#include "stm32f1xx_hal_dma.h"
#endif
#ifdef HAL_CORTEX_MODULE_ENABLED
#include "stm32f1xx_hal_cortex.h"
#endif
#ifdef HAL_FLASH_MODULE_ENABLED
#include "stm32f1xx_hal_flash.h"
#endif
#ifdef HAL_PWR_MODULE_ENABLED
#include "stm32f1xx_hal_pwr.h"
#endif

#ifdef USE_FULL_ASSERT
#define assert_param(expr) ((expr) ? (void)0U : assert_failed((uint8_t *)__FILE__, __LINE__))
void assert_failed(uint8_t *file, uint32_t line);
#else
#define assert_param(expr) ((void)0U)
#endif

#endif /* STM32F1xx_HAL_CONF_H */
