#include "mcu.h"

#include "app.h"
#include "board.h"

int main(void)
{
    HAL_Init();
    board_init(); /* board-specific clock tree */

    app_init();

    while (1) {
        app_run();
        HAL_Delay(1);
    }
}
