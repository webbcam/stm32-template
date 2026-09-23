# All targets here come from pinned git submodules — see ../.gitmodules.
# Don't add sources or headers directly under third_party/; vendor code only.

# CMSIS-Core: ARM Cortex-M core headers, family-agnostic.
# Vendor include dirs are marked SYSTEM throughout this file so warnings
# raised inside ST/ARM headers don't surface in our own targets' output.
add_library(cmsis-core INTERFACE)
target_include_directories(cmsis-core SYSTEM INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}/cmsis-core/CMSIS/Core/Include
)

# CMSIS-Device (F4): device headers + the generic CMSIS system init.
# Startup files live under Source/Templates/gcc/ and are picked per-MCU by
# boards/<name>/CMakeLists.txt, not here.
#
# MCU_DEFINE (e.g. STM32F401xC) is set by boards/${BOARD}/board.cmake, included
# by the root CMakeLists.txt *before* this subdirectory — the device headers in
# both cmsis-device-f4 and the HAL below select their register maps from it, so
# it must exist before these sources compile, not just before they link.
if(NOT DEFINED MCU_DEFINE OR NOT DEFINED HAL_CONF_DIR)
    message(FATAL_ERROR "MCU_DEFINE/HAL_CONF_DIR not set — boards/${BOARD}/board.cmake must be include()'d before add_subdirectory(third_party)")
endif()

add_library(cmsis-device-f4 STATIC
    ${CMAKE_CURRENT_LIST_DIR}/cmsis-device-f4/Source/Templates/system_stm32f4xx.c
)
target_include_directories(cmsis-device-f4 SYSTEM PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/cmsis-device-f4/Include
)
target_compile_definitions(cmsis-device-f4 PUBLIC ${MCU_DEFINE})
target_link_libraries(cmsis-device-f4 PUBLIC cmsis-core)

# STM32F4xx HAL/LL driver. Every module is compiled; the ones not enabled in
# the board's stm32f4xx_hal_conf.h compile to empty objects via ST's own
# #ifdef guards. CONFIGURE_DEPENDS re-globs when the submodule pin changes.
file(GLOB HAL_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_LIST_DIR}/stm32f4xx-hal-driver/Src/*.c
)
list(FILTER HAL_SOURCES EXCLUDE REGEX ".*_template\\.c$")

add_library(hal STATIC ${HAL_SOURCES})
target_include_directories(hal SYSTEM PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/stm32f4xx-hal-driver/Inc
    ${HAL_CONF_DIR}   # stm32f4xx_hal_conf.h — board-owned, not vendored
)
target_compile_definitions(hal PUBLIC USE_HAL_DRIVER)
target_link_libraries(hal PUBLIC cmsis-device-f4)
