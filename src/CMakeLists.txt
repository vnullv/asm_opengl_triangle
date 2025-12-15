find_package(glfw3 CONFIG REQUIRED)
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)

add_executable(${PROJECT_NAME} main.cc main.s
        filesystem/read.s
        shaders/loading/shader_loader.s
        shaders/loading/shader_program_loader.s
        shaders/program_log_error.s
        shaders/shader_log_error.s)

target_link_libraries(${PROJECT_NAME}
    PRIVATE glfw ${OPENGL_LIBRARIES} GLEW::GLEW
)