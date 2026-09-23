# Uses MCU_DEFINE / LINKER_SCRIPT / STARTUP_SOURCE from board.cmake
# (include()'d by the root CMakeLists.txt before this subdirectory is added).

add_library(board STATIC ${STARTUP_SOURCE})
target_compile_definitions(board PUBLIC ${MCU_DEFINE})
target_link_options(board INTERFACE -T${LINKER_SCRIPT})
set_target_properties(board PROPERTIES LINK_DEPENDS ${LINKER_SCRIPT})
