# Use nasm and ld
nasm -f elf64 -o bmplib.o bmplib.asm
nasm -f elf64 -o main.o main.asm
ld bmplib.o main.o  -o bmplib
