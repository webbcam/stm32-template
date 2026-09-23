#ifndef APP_APP_H
#define APP_APP_H

void app_init(void);

/* Call once per main-loop tick (~1ms cadence in main.c). */
void app_run(void);

#endif
