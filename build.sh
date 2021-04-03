# Use nasm and ld
nasm -f elf64 -o bmplib.o bmplib.asm && ld bmplib.o -o bmplib
