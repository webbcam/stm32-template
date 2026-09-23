# Variables only — no targets. Include()'d by the root CMakeLists.txt before
# add_subdirectory(third_party), because MCU_DEFINE/MCU_FAMILY/CPU_FLAGS have
# to exist when the HAL and CMSIS-device sources compile, not just when
# everything links.

set(MCU_FAMILY f1)
set(MCU_DEFINE STM32F103xB)

# Cortex-M3: no FPU, so soft-float ABI. Mixing this with the blackpill's
# hard-float objects would not link — hence CPU_FLAGS being per-board.
set(CPU_FLAGS -mcpu=cortex-m3 -mfloat-abi=soft -mthumb)

set(LINKER_SCRIPT ${CMAKE_CURRENT_LIST_DIR}/STM32F103C8TX_FLASH.ld)

# Directory holding this board's stm32f1xx_hal_conf.h (HSE_VALUE, which HAL
# modules are enabled) and mcu.h. The HAL sources need it on their include
# path at their own compile time, same reasoning as MCU_DEFINE above.
set(HAL_CONF_DIR ${CMAKE_CURRENT_LIST_DIR})

# Provided by the cmsis-device-f1 submodule — not hand-written here.
set(STARTUP_SOURCE
    ${CMAKE_SOURCE_DIR}/third_party/cmsis-device-f1/Source/Templates/gcc/startup_stm32f103xb.s
)
