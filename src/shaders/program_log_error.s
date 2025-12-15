.equ GL_LINK_STATUS, 0x8B82

.equ NULL, 0

.section .rodata
  fatal_memory_allocation_str: .asciz "in function get_shader_program_error_log, there has been a fatal memory allocation error. aborting process.\n"

.section .text
  # caller should free the string after use
  # returns null if there was no error, and a string containing the error if there was.
  .globl get_shader_program_error_log # const char* get_shader_program_error_log(int program_id)

  .extern glGetProgramiv
  .extern glGetProgramInfoLog

  .extern malloc
  .extern abort
  .extern printf

get_shader_program_error_log:
  pushq %rbp
  movq %rsp, %rbp
  subq $32, %rsp

  movl %edi, -32(%rbp) # shader program id
  movl $0, -24(%rbp) # success value from glGetProgramiv
  movq $0, -16(%rbp) # info log str ptr from malloc

  movl -32(%rbp), %edi
  movl $GL_LINK_STATUS, %esi
  leaq -24(%rbp), %rdx
  call glGetProgramiv

  movl -24(%rbp), %eax
  testl %eax, %eax
  jz .Lshader_program_error_found

  movl $NULL, %eax
  jmp .Lget_shader_program_error_log_exit

.Lshader_program_error_found:
  movl $512, %edi
  call malloc
  testq %rax, %rax
  jz .Lshader_program_error_fatal_allocation
  movq %rax, -16(%rbp) # store the error str ptr on the stack

  movl -32(%rbp), %edi # shader program id
  movl $512, %esi # maxlength of error buffer
  movl $NULL, %edx # length, leave null.
  movq -16(%rbp), %rcx # error log str ptr
  call glGetShaderInfoLog

  movq -16(%rbp), %rax
  jmp .Lget_shader_program_error_log_exit

.Lshader_program_error_fatal_allocation:
  leaq fatal_memory_allocation_str(%rip), %rdi
  call printf

  call abort

.Lget_shader_program_error_log_exit:
  addq $32, %rsp
  leave
  ret