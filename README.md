# OpenGL Triangle Written in x86-64 Assembly

## Prerequisites
- GLFW
- OpenGL
- GLEW

## Building
```bash
make
```

## Running
```bash
make run
```

## Project Structure
```
src/
├── filesystem
│   └── read.s                      -> contains fs_read_file()
├── main.s                          -> contains main()
└── shaders
    ├── loading
    │   ├── shader_loader.s         -> contains load_vert_shader(), load_frag_shader()
    │   └── shader_program_loader.s -> contains load_shader_program()
    ├── program_log_error.s         -> contains get_shader_program_error_log()
    └── shader_log_error.s          -> contains get_shader_error_log()
```
