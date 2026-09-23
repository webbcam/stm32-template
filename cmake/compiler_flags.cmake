# CPU_FLAGS is board-specific (Cortex-M4F vs M3 differ in -mcpu, FPU and float
# ABI) and comes from boards/<name>/board.cmake, included by the root
# CMakeLists.txt before this file. These affect ABI/codegen so they apply to
# every source in the cross build, vendor code included.
if(NOT DEFINED CPU_FLAGS)
    message(FATAL_ERROR "CPU_FLAGS not set — boards/${BOARD}/board.cmake must be include()'d first")
endif()

add_compile_options(
    ${CPU_FLAGS}
    -ffunction-sections
    -fdata-sections
    -fno-common
)

add_link_options(${CPU_FLAGS})

# Warnings are opt-in per target, not global: link this into our own targets
# (src/) but never into the vendored HAL/CMSIS, whose warnings we can't fix
# and which would otherwise drown out warnings in code we control.
add_library(project_warnings INTERFACE)
target_compile_options(project_warnings INTERFACE
    -Wall
    -Wextra
)
