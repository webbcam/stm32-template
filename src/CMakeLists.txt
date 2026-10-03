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

# `cmake --build --preset <board> --target flash` (or `make flash`). The preset
# supplies OPENOCD_TARGET from copier.yml's board_meta. Always defined, so a
# missing openocd fails at flash time with a message rather than leaving the
# target undefined.
set(OPENOCD_TARGET "" CACHE STRING "OpenOCD target config name, e.g. stm32f4x")
set(OPENOCD_INTERFACE stlink CACHE STRING "OpenOCD interface config name, e.g. stlink")
find_program(OPENOCD openocd)

if(OPENOCD AND OPENOCD_TARGET)
    add_custom_target(flash
        COMMAND ${OPENOCD}
            -f interface/${OPENOCD_INTERFACE}.cfg
            -f target/${OPENOCD_TARGET}.cfg
            -c "program $<TARGET_FILE:${PROJECT_NAME}> verify reset exit"
        DEPENDS ${PROJECT_NAME}
        USES_TERMINAL
        VERBATIM
    )
else()
    if(NOT OPENOCD)
        set(_flash_error "openocd was not found when this build was configured. Install it, then re-run: cmake --preset ${BOARD}")
    else()
        set(_flash_error "OPENOCD_TARGET is not set. Configure with a preset (cmake --preset ${BOARD}) or pass -DOPENOCD_TARGET=<name>.")
    endif()
    add_custom_target(flash
        COMMAND ${CMAKE_COMMAND} -E echo "${_flash_error}"
        COMMAND ${CMAKE_COMMAND} -E false
        VERBATIM
    )
endif()
