# Use nasm and ld
nasm -f elf64 -o bmplib.o bmplib.asm
nasm -f elf64 -o main.o main.asm
nasm -f elf64 -o math.o math.asm
nasm -f elf64 -o level.o level.asm
ld bmplib.o main.o math.o level.o  -o bmplib
