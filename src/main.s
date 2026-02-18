.file "main.s"

# GL
.equ GL_ARRAY_BUFFER, 0x8892
.equ GL_STATIC_DRAW, 0x88E4
.equ GL_TRIANGLES, 0x0004
.equ GL_FLOAT, 0x1406
.equ GL_TRUE, 1
.equ GL_FALSE, 0

# window
.equ WIN_WIDTH, 1280
.equ WIN_HEIGHT, 720

# standard
.equ NULL, 0
.equ TRUE, 1
.equ FALSE, 0
.equ EXIT_FAILURE, -1

# sizes
.equ FLOAT32_BYTE_SIZE, 4

# glfw
.equ GL_COLOR_BUFFER_BIT, 0x00004000
.equ GLFW_RESIZABLE, 0x00020003
.equ GLFW_KEY_ESCAPE, 256

.section .rodata
  # directories
  frag_shader_dir: .asciz "shaders/fragment.glsl"
  vert_shader_dir: .asciz "shaders/vertex.glsl"

  # window information
  window_name_str: .asciz "asm glfw window"
  window_init_failed_str: .asciz "failed to init window!\n"
  window_color:
    .float 0.2, 0.3, 0.4, 1.0 # R, G, B, A

  # error information
  glfw_init_failed_str: .asciz "failed to init glfw!\n"

  info_str: .asciz "press ESC to quit.\n"

  # vertex information
  vertices:
    .float -0.5, -0.5, 0.0 # left
    .float 0.5, -0.5, 0.0 # right
    .float 0.0, 0.5, 0.0 # top
  .equ vertices_size, FLOAT32_BYTE_SIZE * 9

.section .text
  .globl main

  .extern load_frag_shader # src/shaders/loading/shader_loader.s
  .extern load_vert_shader # src/shaders/loading/shader_loader.s
  .extern load_shader_program # src/shaders/loading/shader_program_loader.s

  # libc
  .extern printf

  # glfw
  .extern glfwInit
  .extern glfwWindowHint
  .extern glfwCreateWindow
  .extern glfwMakeContextCurrent
  .extern glfwSwapInterval
  .extern glfwSwapBuffers
  .extern glfwPollEvents
  .extern glfwTerminate
  .extern glfwDestroyWindow
  .extern glfwWindowShouldClose
  .extern glfwGetKey

  # GL - drawing
  .extern glClearColor
  .extern glClear
  # GL - arrays
  .extern glGenVertexArrays
  .extern glGenBuffers
  .extern glBindVertexArray
  .extern glBindBuffer
  .extern glBufferData
  .extern glVertexAttribPointer
  .extern glEnableVertexAttribArray
  # arrays - drawing
  .extern glDrawArrays
  # GL - shaders
  .extern glUseProgram
  .extern glDeleteShader

  # glew
  .extern glewExperimental # bool value
  .extern glewInit

main:
  pushq %rbp
  movq %rsp, %rbp
  subq $48, %rsp

  movl $0, -48(%rbp) # VAO (vertex array object)
  movl $0, -40(%rbp) # VBO (vertex buffer object)
  movq $0, -32(%rbp) # window ptr
  movl $0, -24(%rbp) # vertex shader id
  movl $0, -16(%rbp) # frag shader id
  movl $0, -8(%rbp) # shader program id

  call glfwInit
  testq %rax, %rax
  jz .Lglfw_init_failed # if (glfwInit() == 0) jmp .Lglfw_init_failed

  movl $GLFW_RESIZABLE, %edi
  movl $FALSE, %esi
  call glfwWindowHint # window should not be resizable

  movl $WIN_WIDTH, %edi
  movl $WIN_HEIGHT, %esi
  leaq window_name_str(%rip), %rdx
  movl $NULL, %ecx # monitor  (not needed)
  movl $NULL, %r8d # share    (not needed)
  call glfwCreateWindow
  testq %rax, %rax
  jz .Lwindow_init_failed # if (window_ptr == nullptr) jmp .Lwindow_init_failed

  movq %rax, -32(%rbp) # store the window ptr

  movq %rax, %rdi # window ptr
  call glfwMakeContextCurrent

  movl $1, %edi # vsync ON (swap interval 1)
  call glfwSwapInterval

  movb $TRUE, glewExperimental(%rip)
  call glewInit

  leaq vert_shader_dir(%rip), %rdi
  call load_vert_shader
  movl %eax, -24(%rbp) # store the vertex shader id

  leaq frag_shader_dir(%rip), %rdi
  call load_frag_shader
  movl %eax, -16(%rbp) # store the fragment shader id

  movl -24(%rbp), %edi # vertex id
  movl -16(%rbp), %esi # fragment id
  call load_shader_program
  movl %eax, -8(%rbp) # store the shader program id

  # vertex and fragment shader are no longer needed as they are in the shader program now
  movl -24(%rbp), %edi # vertex shader id
  call glDeleteShader

  movl -16(%rbp), %edi # fragment shader id
  call glDeleteShader

  # create VAO and VBO
  movl $1, %edi # array count (in this case 1)
  leaq -48(%rbp), %rsi # VAO ptr
  call glGenVertexArrays

  movl $1, %edi # buffer count (1 in this case)
  leaq -40(%rbp), %rsi # VBO ptr
  call glGenBuffers

  movl -48(%rbp), %edi # VAO
  call glBindVertexArray

  movl $GL_ARRAY_BUFFER, %edi
  movl -40(%rbp), %esi # VBO
  call glBindBuffer

  movl $GL_ARRAY_BUFFER, %edi
  movl $vertices_size, %esi
  leaq vertices(%rip), %rdx
  movl $GL_STATIC_DRAW, %ecx
  call glBufferData

  movl $0, %edi # index
  call glEnableVertexAttribArray

  movl $0, %edi # index
  movl $3, %esi # size
  movl $GL_FLOAT, %edx # type
  movl $GL_FALSE, %ecx # isNormalized
  movl $FLOAT32_BYTE_SIZE, %r8d
  imul $3, %r8d # 3 floats in a vertex
  movl $NULL, %r9d # offset
  call glVertexAttribPointer

  movl $GL_ARRAY_BUFFER, %edi
  movl $0, %esi
  call glBindBuffer # unbind the VBO

  movl $0, %edi
  call glBindVertexArray # unbind the VAO

  leaq info_str(%rip), %rdi
  call printf

  jmp .Lloop_should_run

.Lmain_loop:
  movq -32(%rbp), %rdi # window ptr
  movl $GLFW_KEY_ESCAPE, %esi
  call glfwGetKey
  testq %rax, %rax
  jnz .Lexit_loop

  leaq window_color(%rip), %rax
  movss (%rax), %xmm0 # R
  movss 4(%rax), %xmm1 # G
  movss 8(%rax), %xmm2 # B
  movss 12(%rax), %xmm3 # A
  call glClearColor

  movl $GL_COLOR_BUFFER_BIT, %edi
  call glClear

  movl -8(%rbp), %edi # shader program id
  call glUseProgram

  movl -48(%rbp), %edi # VAO
  call glBindVertexArray

  movl $GL_TRIANGLES, %edi
  movl $0, %esi # first
  movl $3, %edx # verticies count
  call glDrawArrays

  movl $0, %edi
  call glBindVertexArray # unbind vertex array after using

  movq -32(%rbp), %rdi
  call glfwSwapBuffers

  call glfwPollEvents

.Lloop_should_run:
  movq -32(%rbp), %rdi # window ptr
  call glfwWindowShouldClose
  test %rax, %rax
  jz .Lmain_loop # if (should_close != true) jmp .Lmain_loop

.Lexit_loop: # fall through if should close
  movl $1, %edi # count
  leaq -48(%rbp), %rsi # VAO ptr
  call glDeleteVertexArrays

  movl $1, %edi # count
  leaq -40(%rbp), %rsi # VBO ptr
  call glDeleteBuffers

  movl -8(%rbp), %edi # shader program id
  call glDeleteProgram

  movq -32(%rbp), %rdi
  call glfwDestroyWindow

  call glfwTerminate

  xorq %rax, %rax # return exit success
  jmp .Lexit

.Lwindow_init_failed:
  leaq window_init_failed_str(%rip), %rdi
  call printf
  call glfwTerminate

  movq $EXIT_FAILURE, %rax
  jmp .Lexit

.Lglfw_init_failed:
  leaq glfw_init_failed_str(%rip), %rdi
  call printf

  movq $EXIT_FAILURE, %rax

.Lexit:
  addq $48, %rsp
  leave
  ret

.end
