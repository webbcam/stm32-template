add_library(app STATIC
    app.c
)
target_include_directories(app PUBLIC ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(app
    PUBLIC drivers
    PRIVATE project_warnings
)
