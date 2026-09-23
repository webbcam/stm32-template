# Variables only — no targets. Include()'d by the root CMakeLists.txt before
# add_subdirectory(third_party), because MCU_DEFINE/MCU_FAMILY/CPU_FLAGS have
# to exist when the HAL and CMSIS-device sources compile, not just when
# everything links.

set(MCU_FAMILY f4)
set(MCU_DEFINE STM32F401xC)

# Cortex-M4F: hard-float ABI with the single-precision FPU.
set(CPU_FLAGS -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb)

set(LINKER_SCRIPT ${CMAKE_CURRENT_LIST_DIR}/STM32F401CCUX_FLASH.ld)

# Directory holding this board's stm32f4xx_hal_conf.h (HSE_VALUE, which HAL
# modules are enabled) and mcu.h. The HAL sources need it on their include
# path at their own compile time, same reasoning as MCU_DEFINE above.
set(HAL_CONF_DIR ${CMAKE_CURRENT_LIST_DIR})

# Provided by the cmsis-device-f4 submodule — not hand-written here.
set(STARTUP_SOURCE
    ${CMAKE_SOURCE_DIR}/third_party/cmsis-device-f4/Source/Templates/gcc/startup_stm32f401xc.s
)
