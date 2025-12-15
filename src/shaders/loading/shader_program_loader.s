.file "shaders/loading/shader_program_loader.s"

.section .rodata
  shader_link_error_str: .asciz "failed to link shader program. GL error: %s\n"

.section .text
  # returns -1 if failed, and the shader program id if successfull
  .globl load_shader_program # int load_shader_program(int vertex_id, int frag_id);

  .extern get_shader_program_error_log # shaders/program_log_error.s

  .extern glCreateProgram
  .extern glAttachShader
  .extern glLinkProgram

load_shader_program:
  pushq %rbp
  movq %rsp, %rbp
  subq $32, %rsp

  movl %edi, -32(%rbp) # vertex shader id
  movl %esi, -24(%rbp) # fragment shader id
  movl $0, -16(%rbp) # shader_program_id
  movq $0, -8(%rbp) # shader program error log

  call glCreateProgram # create the shader program
  movl %eax, -16(%rbp) # store the shader program id on the stack

  movl -16(%rbp), %edi # shader program id
  movl -32(%rbp), %esi # vertex shader id
  call glAttachShader # attach the vertex shader

  movl -16(%rbp), %edi # shader program id
  movl -24(%rbp), %esi # vertex shader id
  call glAttachShader # attach the fragment shader

  movl -16(%rbp), %edi
  call glLinkProgram

  movl -16(%rbp), %edi
  call get_shader_program_error_log
  testq %rax, %rax
  jnz .Lshader_link_error # if (shader_error_log_str != nullptr) jmp .Lshader_link_error

  movl -16(%rbp), %eax # return the shader program id
  jmp .Lload_shader_program_exit

.Lshader_link_error:
  # shader error log str is in rax
  movq %rax, -8(%rbp) # store on stack
  leaq shader_link_error_str(%rip), %rdi
  movq %rax, %rsi
  call printf

  movq -8(%rbp), %rdi
  call free # free the error log

  movl $-1, %eax # creation failed.

.Lload_shader_program_exit:
  addq $32, %rsp
  leave
  ret

.end
