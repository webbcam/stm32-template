/*
 * Clock tree for the bluepill (STM32F103C8T6, 8MHz HSE crystal).
 * Note how different this is from the F4 equivalent: F1 uses a PLL
 * multiplier and HSE prediv rather than the F4's PLLM/PLLN/PLLP/PLLQ. That
 * incompatibility is why clock setup is board-owned rather than shared.
 */
#include "board.h"

#include "mcu.h"

static void error_handler(void)
{
    __disable_irq();
    while (1) {
    }
}

/* HSE 8MHz -> 72MHz SYSCLK (PREDIV=1, PLLMUL=9). APB1 capped at 36MHz. */
void board_init(void)
{
    RCC_OscInitTypeDef osc = {0};
    RCC_ClkInitTypeDef clk = {0};

    osc.OscillatorType = RCC_OSCILLATORTYPE_HSE;
    osc.HSEState = RCC_HSE_ON;
    osc.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
    osc.PLL.PLLState = RCC_PLL_ON;
    osc.PLL.PLLSource = RCC_PLLSOURCE_HSE;
    osc.PLL.PLLMUL = RCC_PLL_MUL9;
    if (HAL_RCC_OscConfig(&osc) != HAL_OK) {
        error_handler();
    }

    clk.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
                    RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
    clk.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    clk.AHBCLKDivider = RCC_SYSCLK_DIV1;
    clk.APB1CLKDivider = RCC_HCLK_DIV2;
    clk.APB2CLKDivider = RCC_HCLK_DIV1;
    if (HAL_RCC_ClockConfig(&clk, FLASH_LATENCY_2) != HAL_OK) {
        error_handler();
    }
}
