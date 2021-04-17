# Use nasm and ld
nasm -f elf64 -g -o bmplib.o bmplib.asm
nasm -f elf64 -g -o main.o main.asm
nasm -f elf64 -g -o math.o math.asm
nasm -f elf64 -g -o level.o level.asm
nasm -f elf64 -g -o player.o player.asm
ld bmplib.o main.o math.o level.o player.o  -o bmplib
