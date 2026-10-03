add_subdirectory(drivers)
add_subdirectory(app)

add_executable(${PROJECT_NAME} main.c)

# Land the artifacts at the top of the build dir (build/<preset>/) rather than
# build/<preset>/src/, so the paths in README.md are the real ones.
set_target_properties(${PROJECT_NAME} PROPERTIES
    SUFFIX ".elf"
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    app
    drivers
    hal
    board
    project_warnings
)

target_link_options(${PROJECT_NAME} PRIVATE
    -Wl,-Map=${CMAKE_BINARY_DIR}/${PROJECT_NAME}.map
)

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${PROJECT_NAME}> $<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}> $<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.bin
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${PROJECT_NAME}>
)

# `cmake --build --preset <board> --target flash` (or `make flash`). Pick the
# tool with -DFLASH_TOOL=<tool> at configure time; it sticks in the cache.
#
#   openocd   OpenOCD; the preset supplies OPENOCD_TARGET from copier.yml's
#             board_meta, and OPENOCD_INTERFACE picks the probe config
#   stlink    st-flash from the open-source stlink tools; writes the .bin
#   cubeprog  ST's STM32_Programmer_CLI (STM32CubeProgrammer) over SWD
#
# Always defined, so a missing tool fails at flash time with a message rather
# than leaving the target undefined.
set(FLASH_TOOL openocd CACHE STRING "Flash tool: openocd, stlink or cubeprog")
set_property(CACHE FLASH_TOOL PROPERTY STRINGS openocd stlink cubeprog)

# Declared whatever the tool, since every preset sets OPENOCD_TARGET and CMake
# warns about command-line variables the project never reads.
set(OPENOCD_TARGET "" CACHE STRING "OpenOCD target config name, e.g. stm32f4x")
set(OPENOCD_INTERFACE stlink CACHE STRING "OpenOCD interface config name, e.g. stlink")

unset(_flash_error)
if(FLASH_TOOL STREQUAL "openocd")
    find_program(OPENOCD openocd)
    set(_flash_exe ${OPENOCD})
    set(_flash_program openocd)
    set(_flash_args
        -f interface/${OPENOCD_INTERFACE}.cfg
        -f target/${OPENOCD_TARGET}.cfg
        -c "program $<TARGET_FILE:${PROJECT_NAME}> verify reset exit"
    )
    if(NOT OPENOCD_TARGET)
        set(_flash_error "OPENOCD_TARGET is not set. Configure with a preset (cmake --preset ${BOARD}) or pass -DOPENOCD_TARGET=<name>.")
    endif()
elseif(FLASH_TOOL STREQUAL "stlink")
    find_program(ST_FLASH st-flash)
    set(_flash_exe ${ST_FLASH})
    set(_flash_program st-flash)
    # Raw binary, so st-flash needs the load address: the flash base, which is
    # 0x08000000 on every STM32 family this template supports. Verifies by default.
    set(_flash_args
        --reset write $<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.bin 0x08000000
    )
elseif(FLASH_TOOL STREQUAL "cubeprog")
    # Not usually on PATH; the HINTS are STM32CubeProgrammer's default install
    # locations on macOS and Linux.
    find_program(STM32_PROGRAMMER_CLI STM32_Programmer_CLI
        HINTS
            /Applications/STMicroelectronics/STM32Cube/STM32CubeProgrammer/STM32CubeProgrammer.app/Contents/MacOs/bin
            $ENV{HOME}/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin
    )
    set(_flash_exe ${STM32_PROGRAMMER_CLI})
    set(_flash_program STM32_Programmer_CLI)
    set(_flash_args -c port=SWD -w $<TARGET_FILE:${PROJECT_NAME}> -v -rst)
else()
    message(FATAL_ERROR "Unknown FLASH_TOOL '${FLASH_TOOL}'. Choose one of: openocd, stlink, cubeprog")
endif()

if(NOT _flash_exe)
    set(_flash_error "${_flash_program} (FLASH_TOOL=${FLASH_TOOL}) was not found when this build was configured. Install it, then re-run: cmake --preset ${BOARD}")
endif()

if(_flash_error)
    add_custom_target(flash
        COMMAND ${CMAKE_COMMAND} -E echo "${_flash_error}"
        COMMAND ${CMAKE_COMMAND} -E false
        VERBATIM
    )
else()
    add_custom_target(flash
        COMMAND ${_flash_exe} ${_flash_args}
        DEPENDS ${PROJECT_NAME}
        USES_TERMINAL
        VERBATIM
    )
endif()
