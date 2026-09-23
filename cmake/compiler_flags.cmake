# Cortex-M4F flags shared by every source file in the cross build, vendor code
# included — these affect ABI/codegen, so they must apply everywhere.
# Board-specific MCU defines live in boards/<name>/board.cmake.
add_compile_options(
    -mcpu=cortex-m4
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
    -mthumb
    -ffunction-sections
    -fdata-sections
    -fno-common
)

# Warnings are opt-in per target, not global: link this into our own targets
# (src/) but never into the vendored HAL/CMSIS, whose warnings we can't fix
# and which would otherwise drown out warnings in code we control.
add_library(project_warnings INTERFACE)
target_compile_options(project_warnings INTERFACE
    -Wall
    -Wextra
)

add_link_options(
    -mcpu=cortex-m4
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
    -mthumb
)
