# Standalone host-native CMake project — not a subdirectory of the firmware
# build. Configure/build it directly: `cmake -S test -B build/host-test`.
# Never mixed with the arm-none-eabi toolchain or the `hal`/`board` targets.

cmake_minimum_required(VERSION 3.25)
project(host_tests C)

# build/host-test/compile_commands.json, for clangd (see .clangd).
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(FW_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(THIRD_PARTY ${FW_ROOT}/third_party)

find_program(RUBY_EXECUTABLE ruby REQUIRED)

enable_testing()

add_library(unity STATIC ${THIRD_PARTY}/unity/src/unity.c)
target_include_directories(unity PUBLIC ${THIRD_PARTY}/unity/src)

add_library(cmock STATIC ${THIRD_PARTY}/cmock/src/cmock.c)
target_include_directories(cmock PUBLIC ${THIRD_PARTY}/cmock/src)
target_link_libraries(cmock PUBLIC unity)

# CMock-generated mock of src/drivers/led.h, so src/app/app.c can be tested
# without a real HAL/board underneath it.
set(MOCK_DIR ${CMAKE_CURRENT_BINARY_DIR}/mocks)
file(MAKE_DIRECTORY ${MOCK_DIR})

add_custom_command(
    OUTPUT ${MOCK_DIR}/mock_led.c ${MOCK_DIR}/mock_led.h
    COMMAND ${RUBY_EXECUTABLE} ${THIRD_PARTY}/cmock/lib/cmock.rb
            --mock_prefix=mock_
            --mock_path=${MOCK_DIR}
            ${FW_ROOT}/src/drivers/led.h
    DEPENDS ${FW_ROOT}/src/drivers/led.h
    COMMENT "CMock: generating mock_led from src/drivers/led.h"
)
add_custom_target(generate_mocks DEPENDS ${MOCK_DIR}/mock_led.c)

# Real app.c, real led.h declarations, mocked led.c — no hal/board involved.
add_library(app_under_test STATIC ${FW_ROOT}/src/app/app.c)
target_include_directories(app_under_test PUBLIC
    ${FW_ROOT}/src/app
    ${FW_ROOT}/src/drivers
)

add_executable(test_app unit/test_app.c ${MOCK_DIR}/mock_led.c)
add_dependencies(test_app generate_mocks)
target_include_directories(test_app PRIVATE ${MOCK_DIR})
target_link_libraries(test_app PRIVATE app_under_test cmock unity)

add_test(NAME test_app COMMAND test_app)
