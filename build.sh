# Use nasm and ld
nasm -f elf64 -o bmplib.o bmplib.asm
nasm -f elf64 -o main.o main.asm
nasm -f elf64 -o math.o math.asm
ld bmplib.o main.o math.o  -o bmplib
