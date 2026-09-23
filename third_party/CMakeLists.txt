# All targets here come from pinned git submodules — see ../.gitmodules.
# Don't add sources or headers directly under third_party/; vendor code only.
#
# Vendor include dirs are marked SYSTEM throughout so warnings raised inside
# ST/ARM headers don't surface in our own targets' output.
#
# MCU_DEFINE / MCU_FAMILY / HAL_CONF_DIR come from boards/${BOARD}/board.cmake,
# include()'d by the root CMakeLists.txt *before* this subdirectory — the
# device headers select their register maps from MCU_DEFINE, so it must exist
# before these sources compile, not just before they link.
if(NOT DEFINED MCU_DEFINE OR NOT DEFINED HAL_CONF_DIR OR NOT DEFINED MCU_FAMILY)
    message(FATAL_ERROR "MCU_DEFINE/MCU_FAMILY/HAL_CONF_DIR not set — boards/${BOARD}/board.cmake must be include()'d before add_subdirectory(third_party)")
endif()

# Per-family submodule layout. Only the selected family's targets are defined,
# so a project never compiles another family's HAL.
if(MCU_FAMILY STREQUAL "f4")
    set(_device_dir cmsis-device-f4)
    set(_device_src Source/Templates/system_stm32f4xx.c)
    set(_hal_dir stm32f4xx-hal-driver)
elseif(MCU_FAMILY STREQUAL "f1")
    set(_device_dir cmsis-device-f1)
    set(_device_src Source/Templates/system_stm32f1xx.c)
    set(_hal_dir stm32f1xx-hal-driver)
else()
    message(FATAL_ERROR "Unknown MCU_FAMILY '${MCU_FAMILY}' — add its submodules and a branch here (see boards/README.md)")
endif()

# CMSIS-Core: ARM Cortex-M core headers, shared by every family.
add_library(cmsis-core INTERFACE)
target_include_directories(cmsis-core SYSTEM INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}/cmsis-core/CMSIS/Core/Include
)

# CMSIS-Device: device headers + the generic CMSIS system init. Startup files
# live under Source/Templates/gcc/ and are picked per-MCU by board.cmake.
add_library(cmsis-device STATIC
    ${CMAKE_CURRENT_LIST_DIR}/${_device_dir}/${_device_src}
)
target_include_directories(cmsis-device SYSTEM PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/${_device_dir}/Include
)
target_compile_definitions(cmsis-device PUBLIC ${MCU_DEFINE})
target_link_libraries(cmsis-device PUBLIC cmsis-core)

# STM32 HAL/LL driver. Every module is compiled; the ones not enabled in the
# board's stm32<family>xx_hal_conf.h compile to empty objects via ST's own
# #ifdef guards. CONFIGURE_DEPENDS re-globs when the submodule pin changes.
file(GLOB HAL_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_LIST_DIR}/${_hal_dir}/Src/*.c
)
list(FILTER HAL_SOURCES EXCLUDE REGEX ".*_template\\.c$")

add_library(hal STATIC ${HAL_SOURCES})
target_include_directories(hal SYSTEM PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/${_hal_dir}/Inc
    ${HAL_CONF_DIR}   # stm32<family>xx_hal_conf.h + mcu.h — board-owned
)
target_compile_definitions(hal PUBLIC USE_HAL_DRIVER)
target_link_libraries(hal PUBLIC cmsis-device)
