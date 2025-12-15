.file "shaders/shader_log_error.s"

.equ GL_COMPILE_STATUS, 0x8B81

.equ NULL, 0

.section .rodata
  fatal_memory_allocation_str: .asciz "in function get_shader_error_log, there has been a fatal memory allocation error. aborting process.\n"

.section .text
   # caller should free the string after use
   # returns null if there was no error, and a string containing the error if there was.
  .globl get_shader_error_log # const char* get_shader_error_log(int shader_id)

  .extern glGetShaderiv
  .extern glGetShaderInfoLog

  .extern printf
  .extern malloc
  .extern abort

get_shader_error_log:
  pushq %rbp
  movq %rsp, %rbp
  subq $32, %rsp

  movl %edi, -32(%rbp) # shader id
  movl $0, -24(%rbp) # success value from glGetShaderiv
  movq $0, -16(%rbp) # info log str ptr from malloc

  # shader id already in edi
  movl $GL_COMPILE_STATUS, %esi
  leaq -24(%rbp), %rdx # success value
  call glGetShaderiv

  movl -24(%rbp), %eax # success value
  testl %eax, %eax
  jz .Lshader_error_found

  movl $NULL, %eax
  jmp .Lget_shader_error_log_exit

.Lshader_error_found:
  movl $512, %edi # error buffer size
  call malloc
  testq %rax, %rax
  jz .Lshader_error_fatal_allocation
  movq %rax, -16(%rbp) # store the error log ptr

  movl -32(%rbp), %edi # shader id
  movl $512, %esi # maxlength of error buffer
  movl $NULL, %edx # length, leave null.
  movq -16(%rbp), %rcx # error log str ptr
  call glGetShaderInfoLog

  movq -16(%rbp), %rax
  jmp .Lget_shader_error_log_exit

.Lshader_error_fatal_allocation:
  leaq fatal_memory_allocation_str(%rip), %rdi
  call printf

  call abort

.Lget_shader_error_log_exit:
  addq $32, %rsp
  leave
  ret

.end