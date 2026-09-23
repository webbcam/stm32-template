#include "unity.h"

#include "app.h"
#include "mock_led.h"

void setUp(void)
{
    mock_led_Init();
}

/* Verify() is what makes an unmet expectation fail the test — without it a
 * test that never calls the expected function still passes. */
void tearDown(void)
{
    mock_led_Verify();
    mock_led_Destroy();
}

void test_app_run_toggles_led_every_500_ticks(void)
{
    led_init_Expect();
    app_init();

    for (int i = 0; i < 499; i++) {
        app_run();
    }

    led_toggle_Expect();
    app_run();
}

int main(void)
{
    UNITY_BEGIN();
    RUN_TEST(test_app_run_toggles_led_every_500_ticks);
    return UNITY_END();
}
