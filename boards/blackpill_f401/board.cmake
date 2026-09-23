# Variables only — no targets. Include()'d by the root CMakeLists.txt before
# add_subdirectory(third_party), because MCU_DEFINE has to exist when the HAL
# and CMSIS-device sources compile, not just when everything links.

set(MCU_DEFINE STM32F401xC)
set(LINKER_SCRIPT ${CMAKE_CURRENT_LIST_DIR}/STM32F401CCUX_FLASH.ld)

# Directory holding this board's stm32f4xx_hal_conf.h (HSE_VALUE, which HAL
# modules are enabled). The HAL sources need it on their include path at
# their own compile time, same reasoning as MCU_DEFINE below.
set(HAL_CONF_DIR ${CMAKE_CURRENT_LIST_DIR})

# Provided by the cmsis-device-f4 submodule — not hand-written here.
set(STARTUP_SOURCE
    ${CMAKE_SOURCE_DIR}/third_party/cmsis-device-f4/Source/Templates/gcc/startup_stm32f401xc.s
)
