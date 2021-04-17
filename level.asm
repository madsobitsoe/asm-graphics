        BITS 64
        global draw_level
        global level
        global level_check_if_point_is_wall
        global tile_size
        extern rectangle

draw_level:
        ;; addr of buf to write to in rdi
        ;; img_width,img_height (in pixels) as img_width << 32 | img_height should be in rcx
        push rdi
        push rax
        push rcx
        push rbx
        push rdx
        push r15
        mov r10, 0x0
        mov r10, rcx
        mov r9d, dword[tile_size]
        xor rax, rax            ; rax = current tile_x
        xor rcx, rcx            ; rcx = current tile_y

draw_level_loop:
        ;; Check if completely done
        cmp ecx, dword [map_height]
        jge draw_level_done
        ;; Check if done with this row
        cmp eax, dword [map_width]
        jl draw_level_loop_row
        inc rcx                    ; increment tile_y
        mov rax, 0                 ; reset tile

        jmp draw_level_loop
draw_level_loop_row:
        ;; set up call to rectangle
        push rax                   ; tile_x
        push rcx                   ; tile_y
        push rcx                   ; tile_y
        push rax                   ; tile_x
        ;; get color - check if tile is wall
        ;; index is x + y * map-width
        xchg rax, rcx
        mov ebx, dword[map_width]
        mul rbx                    ; y * map_width
        add rax, rcx               ; + x
        cmp byte [level + rax], 1  ; is this a wall?
        je color_wall
        mov rbx, 0x00FFFF
        jmp color_found
color_wall:

        ;; mov rbx,r15
        ;; add r15, 0x10
        mov rbx, 0xFF0000
color_found:
        pop rax                    ; tile_x
        mul r9                     ; x * tile_size for start-x
        pop rcx                    ; tile_y
        xchg rax, rcx
        mul r9                     ; y * tile_size for start-y
        xchg rax, rcx
        ;; Set up x << 48 | y << 32 | width << 16 | height
        shl rax, 16
        and ecx, 0xffff
        or rax, rcx
        shl rax, 16
        or rax, r9
        shl rax, 16
        or rax, r9
        push r9                    ; tile_size
        mov rcx, r10               ; img_width, img_height in rcx!
        push r10                   ; save img_width, img_height
        call rectangle
        pop r10                    ; restore img_width, img_height
        pop r9                     ; tile_size
        pop rcx                    ; tile_y
        pop rax                    ; tile_x
        inc rax                    ; next tile in row
        jmp draw_level_loop

draw_level_done:
        pop r15
        pop rdx
        pop rbx
        pop rcx
        pop rax
        pop rdi
        ret


level_check_if_point_is_wall:
        ;; point to check as
        ;; rax = x
        ;; rdx = y
        ;; returns the value of that location in the map
        ;; e.g. 0 = no wall, other value = wall of type N
        push rax
        push rcx
        push rdx
        ;; int3
        xor rdx, rdx
        div dword[tile_size]    ; x / tile_size is x-offset into level
        pop rdx
        push rax
        xchg rax, rdx
        xor rdx, rdx
        div dword[tile_size]   ; y / tile_size is y-offset
        mul dword[map_width]   ; y / tile_size * map_width + (x / tile_size) is index
        mov rcx, rax
        pop rax
        add rcx, rax
        xor rax, rax
        ;; int3
        mov al, byte [level + rcx]
        pop rcx
        add rsp, 8
        ret


        section .data
map_width:      dd 16
map_height:     dd 16
tile_size:      dd 16

level:
        dq 0x0101010101010101
        dq 0x0101010101010101
        dq 0x0000000000000001
        dq 0x0100000000000000
        dq 0x0001010100000001
        dq 0x0100000000000000
        dq 0x0000000000000001
        dq 0x0100000000000000
        dq 0x0000000100000001
        dq 0x0100000100000000
        dq 0x0000000100000001
        dq 0x0100000100000000
        dq 0x0000000100000001
        dq 0x0100000100000000
        dq 0x0000000100000001
        dq 0x0100000100000000
        dq 0x0000000100000001
        dq 0x0100000100000000
        dq 0x0000000100000001
        dq 0x0100000000000000
        dq 0x0000000100000001
        dq 0x0100000100000000
        dq 0x0000000100000001
        dq 0x0100000000000000
        dq 0x0000000000000001
        dq 0x0100000000000000
        dq 0x0101010101010101
        dq 0x0100000000000101
        dq 0x0000000000000001
        dq 0x0100000000000000
        dq 0x0101010101010101
        dq 0x0101010101010101
