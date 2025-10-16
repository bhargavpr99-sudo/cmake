cmake_minimum_required(VERSION 3.10)
project(MyFirmware C)

set(CMAKE_C_STANDARD 11)

# Detect objcopy (arm-none-eabi-objcopy or objcopy)
find_program(CMAKE_OBJCOPY NAMES arm-none-eabi-objcopy objcopy)

add_executable(myfirmware.elf
    src/main.c
)

if(CMAKE_OBJCOPY)
    add_custom_command(TARGET myfirmware.elf POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:myfirmware.elf> ${CMAKE_CURRENT_BINARY_DIR}/myfirmware.bin
        COMMENT "Generating .bin from .elf"
    )
else()
    message(WARNING "objcopy not found. Skipping binary generation step.")
endif()
