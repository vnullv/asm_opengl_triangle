.file "shaders/shader_loader.s"

.equ GL_FRAGMENT_SHADER, 0x8B30
.equ GL_VERTEX_SHADER, 0x8B31

.equ NULL, 0

.section .rodata
  vert_shader_read_fail_str: .asciz "failed to read vertex shader at '%s'\n"
  vert_shader_comp_fail_str: .asciz "failed to compile vertex shader. GL error: %s\n"

  frag_shader_read_fail_str: .asciz "failed to read fragment shader at '%s'\n"
  frag_shader_comp_fail_str: .asciz "failed to compile fragment shader. GL error: %s\n"

.section .text
  # both return -1 if creation failed, and a id if creation was successful.
  .globl load_vert_shader # int load_vert_shader(const char* vert_shader_path)
  .globl load_frag_shader # int load_frag_shader(const char* frag_shader_path)

  .extern fs_read_file # src/filesystem/read.s

  .extern get_shader_error_log # src/shaders/shader_log_error.s

  .extern malloc
  .extern free
  .extern printf

  .extern glCreateShader
  .extern glShaderSource
  .extern glCompileShader
  .extern glGetShaderiv

load_vert_shader:
  pushq %rbp
  movq %rsp, %rbp
  subq $32, %rsp

  movq %rdi, -32(%rbp) # file path str
  movq $0, -24(%rbp) # file contents ptr (from fs_read_file)
  movl $0, -16(%rbp) # vertex_shader_id
  movq $0, -8(%rbp) # error log str ptr

  # file path already in rdi
  call fs_read_file
  test %rax, %rax
  jz .Lvert_file_read_fail # if (file_contents_ptr == nullptr) jmp .Lvert_file_read_fail
  movq %rax, -24(%rbp) # file contents ptr

  movl $GL_VERTEX_SHADER, %edi # tell gl to create a vertex shader
  call glCreateShader
  movl %eax, -16(%rbp) # vertex shader id

  movl -16(%rbp), %edi # vertex shader id
  movl $1, %esi # shader count (1)
  leaq -24(%rbp), %rdx # file contents
  movl $NULL, %ecx # length. ignore.
  call glShaderSource

  movq -24(%rbp), %rdi
  call free # free the file contents. no longer needed.

  movl -16(%rbp), %edi # vertex shader id
  call glCompileShader # compile the vertex shader

  # now check if compilation had any errors
  movl -16(%rbp), %edi # vertex shader id
  call get_shader_error_log # returns null if no error was found, a string pointer if a error was found
  testq %rax, %rax
  jnz .Lvert_compilation_error # if (compilation_str != nullptr) jmp .Lvert_compilation_error

  movl -16(%rbp), %eax
  jmp .Lload_vert_shader_exit

.Lvert_compilation_error:
  movq %rax, -8(%rbp) # store the error log str ptr
  leaq vert_shader_comp_fail_str(%rip), %rdi
  movq -8(%rbp), %rsi # the error string is is rax, move to rsi
  call printf

  movq -8(%rbp), %rdi # free the error log str
  call free

  movl $-1, %eax # return -1 (failed to create vert shader)
  jmp .Lload_vert_shader_exit # exit

.Lvert_file_read_fail:
  leaq vert_shader_read_fail_str(%rip), %rdi
  movq -32(%rbp), %rsi # vertex file path str
  call printf

  movl $-1, %eax # failed to create vert shader

.Lload_vert_shader_exit:
  addq $32, %rsp
  leave
  ret

# almost the same as the previous function
load_frag_shader:
  pushq %rbp
  movq %rsp, %rbp
  subq $32, %rsp

  movq %rdi, -32(%rbp) # file path str
  movq $0, -24(%rbp) # file contents ptr (from fs_read_file)
  movl $0, -16(%rbp) # fragment_shader_id
  movq $0, -8(%rbp) # error log str ptr

  # file path already in rdi
  call fs_read_file
  test %rax, %rax
  jz .Lfrag_file_read_fail # if (file_contents_ptr == nullptr) jmp .Lfrag_file_read_fail
  movq %rax, -24(%rbp)

  movl $GL_FRAGMENT_SHADER, %edi
  call glCreateShader
  movl %eax, -16(%rbp) # fragment shader id

  movl -16(%rbp), %edi # frag shader id
  movl $1, %esi # shader count (1)
  leaq -24(%rbp), %rdx # file contents
  movl $NULL, %ecx # length. ignore this.
  call glShaderSource

  movq -24(%rbp), %rdi # file contents ptr
  call free # free the file contents. no longer needed.

  movl -16(%rbp), %edi # fragment shader id
  call glCompileShader # compile the vertex shader

  # now check if compilation had any errors
  movl -16(%rbp), %edi # fragment shader id
  call get_shader_error_log
  testq %rax, %rax
  jnz .Lfrag_compilation_error

  movl -16(%rbp), %eax # return fragment shader id
  jmp .Lload_frag_shader_exit

.Lfrag_compilation_error:
  movq %rax, -8(%rbp) # error log in rax, move to the stack
  leaq frag_shader_comp_fail_str(%rip), %rdi
  movq %rax, %rsi # error log
  call printf

  movq -8(%rbp), %rdi
  call free # free the error log str

  movl $-1, %eax
  jmp .Lload_frag_shader_exit # shader creation failed.

.Lfrag_file_read_fail:
  leaq frag_shader_read_fail_str(%rip), %rdi
  movq -32(%rbp), %rsi # file path str
  call printf

  movq $-1, %rax

.Lload_frag_shader_exit:
  addq $32, %rsp
  leave
  ret

.end