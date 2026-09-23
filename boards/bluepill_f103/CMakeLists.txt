# Uses MCU_DEFINE / LINKER_SCRIPT / STARTUP_SOURCE from board.cmake
# (include()'d by the root CMakeLists.txt before this subdirectory is added).

add_library(board STATIC
    ${STARTUP_SOURCE}
    board.c
)
target_include_directories(board PUBLIC ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(board
    PUBLIC hal
    PRIVATE project_warnings
)
target_link_options(board INTERFACE -T${LINKER_SCRIPT})
set_target_properties(board PROPERTIES LINK_DEPENDS ${LINKER_SCRIPT})
