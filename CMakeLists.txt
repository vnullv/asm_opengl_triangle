cmake_minimum_required(VERSION 4.0)
project(asm_main)

enable_language(ASM-ATT)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_subdirectory(src)