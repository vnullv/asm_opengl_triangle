.file "filesystem/read.s"

.equ NULL, 0

.equ SEEK_SET, 0
.equ SEEK_CUR, 1
.equ SEEK_END, 2

.equ CHAR_BYTE_SIZE, 1

.section .rodata
  file_mode_str: .asciz "r"

  #error checking
  failed_to_open_str: .asciz "failed to open file\n"
  failed_to_allocate_str: .asciz "failed to allocate file buffer\n"

.section .text
  # caller should free the string after use.
  .globl fs_read_file # const char* read_file(const char* file_name);

  .extern fopen
  .extern fseek
  .extern ftell
  .extern malloc
  .extern fread
  .extern fclose
  .extern free
  .extern printf

fs_read_file:
  pushq %rbp
  movq %rsp, %rbp
  subq $32, %rsp

  movq %rdi, -32(%rbp) # filename
  movq $0, -24(%rbp) # file ptr
  movq $0, -16(%rbp) # file size
  movq $0, -8(%rbp) # file buffer ptr

  movq -32(%rbp), %rdi # name of the file
  leaq file_mode_str(%rip), %rsi # the mode of access, in this case "r"
  call fopen
  testq %rax, %rax
  jz .Lfailed_to_open_file # if (file_ptr == nullptr) (the file didnt open)
  movq %rax, -24(%rbp) # store file ptr on the stack

  movq %rax, %rdi # file_ptr
  movl $0, %esi
  movl $SEEK_END, %edx # go to end of file
  call fseek # go to the end of the file

  movq -24(%rbp), %rdi # file_ptr
  call ftell # get the file size
  movq %rax, -16(%rbp) # store file size on the stack

  movq -24(%rbp), %rdi # file_ptr
  movl $0, %esi
  movl $SEEK_SET, %edx # start of file
  call fseek # go back to the start of the file

  movq -16(%rbp), %rdi # size of the file
  addq $1, %rdi # add one
  call malloc # allocate memory for the file buffer
  testq %rax, %rax # if pointer is 0 (allocation failed)
  jz .Lfailed_to_allocate_buffer_memory
  movq %rax, -8(%rbp) # store file buffer ptr

  # read file into buffer
  movq -8(%rbp), %rdi # file buffer ptr
  movl $1, %esi
  movq -16(%rbp), %rdx # file size
  movq -24(%rbp), %rcx # file ptr
  call fread
  # rax = bytes read
  movq -16(%rbp), %rcx # file size
  cmpq %rax, %rcx # if (bytes_read != file_size)
  jne .Lfailed_to_read_file

  movq -8(%rbp), %rax # file contents array
  movq -16(%rbp), %rsi # last index (file_size)
  leaq (%rax, %rsi, 1), %rdi
  movb $0, (%rdi) # null terminate the array

  movq -24(%rbp), %rdi # file ptr
  call fclose # close the file

  movq -8(%rbp), %rax # return the file contents array ptr
  jmp .Lfs_read_file_exit

.Lfailed_to_read_file:
  movq -8(%rbp), %rdi
  call free # free the buffer
  movq -24(%rbp), %rdi
  call fclose

  movq $NULL, %rax
  jmp .Lfs_read_file_exit

.Lfailed_to_allocate_buffer_memory:
  movq -24(%rbp), %rdi
  call fclose

  leaq failed_to_allocate_str(%rip), %rdi
  call printf

  movq $NULL, %rax
  jmp .Lfs_read_file_exit

.Lfailed_to_open_file:
  leaq failed_to_open_str(%rip), %rdi
  call printf

  movq $NULL, %rax

.Lfs_read_file_exit:
  addq $32, %rsp
  leave
  ret

.end
