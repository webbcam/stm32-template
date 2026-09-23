#include "app.h"

#include "led.h"

#define BLINK_PERIOD_TICKS 500U

static unsigned tick_count;

void app_init(void)
{
    led_init();
    tick_count = 0U;
}

void app_run(void)
{
    tick_count++;
    if (tick_count >= BLINK_PERIOD_TICKS) {
        led_toggle();
        tick_count = 0U;
    }
}
