add_library(drivers STATIC
    led.c
)
target_include_directories(drivers PUBLIC ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(drivers
    PUBLIC hal
    PRIVATE project_warnings
)
