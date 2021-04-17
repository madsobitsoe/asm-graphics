        BITS 64
        global player_get_view
        global player_get_pos
        global player_draw_view_cone
        extern level            ;the map
        extern cast_ray
        extern line
        extern clamp_degrees
        extern level_check_if_point_is_wall
        extern tile_size

player_get_view:
        ;; cast ray from player until a wall is hit
        ;; returns ray as line in rax
        push rbx
        xor rax, rax
        mov ax, word [player_x]
        shl rax, 32
        or  ax, word [player_y]
        mov rbx, 0x20
        shl rbx, 32
        or  bx, word [player_angle]
        call cast_ray
        ;; mov rax, [level]
        pop rbx
        ret

player_draw_view_cone:
        ;; cast rays from player  and draw viewcone
        ;; addr of buf should be in rdi

        ;; color as r << 16 | g << 8 | b should be in rbx
        ;; img_width,img_height (in pixels) as img_width << 32 | img_height should be in rcx
        push rdi
        push rbx
        push rdx
        push r8
        push r9
        push 0x808080           ; color = gray-ish
        xor rax, rax
        mov ax, word [player_x]
        shl rax, 32
        or  ax, word [player_y]
        ;; mov rbx, 0x20           ; distance (for now)
        ;; shl rbx, 32
player_view_cone_loop_setup:
        xor rdx, rdx
        mov dx, word [player_angle]
        mov r9w, word [player_half_fov]
        sub rdx, r9
        xor r8, r8
        mov r8w, word [player_angle]
        add r8, r9 ; end degree
player_view_cone_loop:
        push rax                ; player_x, player_y
        push r8
        push rdx                ; current unclamped degrees
        ;; int3
        xchg rax, rdx           ; put unclamped degrees in rax
        call clamp_degrees      ; clamp them
        call player_cast_ray
        mov edx, eax            ; hit_x << 16 | hit_y
        ;; shr rax, 32             ; distance to wall!
        xor rax, rax
        xor rbx, rbx
        mov ax, word [player_x]
        mov bx, word [player_y]
        shl rax, 16
        or rax, rbx             ; player_x << 16 | player_y
        shl rax, 32
        or rax, rdx             ; player_x << 48 | player_y << 32 | hit_x << 16 | hit_y

        ;; int3
        mov rbx, [rsp+0x18]        ; color
        push rdi
        call line
        pop rdi

        pop rdx                 ; restore unclamped degrees
        add rdx, 1              ; next degree in step
        pop r8
        pop rax

        cmp rdx, r8
        jl player_view_cone_loop
;; player_view_cone_loop:
;;         push rax                ; player_x, player_y
;;         push r8
;;         push rdx                ; current unclamped degrees

;;         xchg rax, rdx           ; put unclamped degrees in rax
;;         call clamp_degrees      ; clamp them
;;         xchg rax, rdx           ; put them back in rdx
;;         mov rbx, 0x40           ; distance
;;         shl rbx, 32
;;         shl rdx, 32             ; clear out upper bits for OR-op
;;         shr rdx, 32
;;         or  rbx, rdx            ; distance << 32 | angle
;;         call cast_ray
;;         pop rdx                 ; restore unclamped degrees
;;         add rdx, 1              ; next degree in step
;;         mov rbx, [rsp+16]        ; color
;;         push rdi
;;         call line
;;         pop rdi
;;         pop r8
;;         pop rax

;;         cmp rdx, r8
;;         jl player_view_cone_loop
player_view_cone_done:
        pop rbx                 ;color
        pop r9                  ;restore
        pop r8                  ;restore
        pop rdx                 ;restore
        pop rbx                 ;restre
        pop rdi                 ;restore
        ret

player_cast_ray:
        ;; cast a ray from player_x,player_y at given angle
        ;; increments distance until wall is hit
        ;; preconds: angle in rax
        ;; returns distance and the hit point in rax
        ;; distance << 32| hit_x << 16 | hit_y
        push rbx
        push rcx
        push rdi
        push rdx
        push rbp
        ;; int3
        mov ecx, dword [tile_size]
        ;; shr rcx, 2              ; tile_size / 8
        mov rcx, 1
        mov rbx, 0              ; current distance to check
        mov edi, eax            ; angle
        push rax
        mov dx, word [player_x]     ; should be player_x << 32 | player_y
        shl rdx, 32
        xor rax, rax
        mov ax, word [player_y]
        or rdx, rax
        pop rax


player_cast_ray_loop:
        ;; int3
        ;; FROM HERE
        push rax
        mov dx, word [player_x]     ; should be player_x << 32 | player_y
        shl rdx, 32
        xor rax, rax
        mov ax, word [player_y]
        or rdx, rax
        pop rax
        ;; TO HERE
        add rbx, rcx            ; add tile_size / 2 to distance we're checking
        ;; push rcx
        ;; push rbx
        shl rbx, 32
        or  rbx, rdi            ; distance << 32 | angle
        mov rax, rdx
        ;; int3
        call cast_ray
        ;; pop rcx
        ;; pop rbx
        mov rbp, rax            ; save ray

        mov edx, eax            ; set up call to wall-check
        shl edx, 16
        shr edx, 16
        shr eax, 16
        push rdx
        call level_check_if_point_is_wall
        pop rdx
        cmp rax, 0
        je player_cast_ray_loop
        ;; int3
        mov eax, ebp
        shl rbx, 32             ; shift distance
        or rax, rbx             ; distance << 32 | hit_x << 16 | hit_y
        pop rbp
        pop rdx
        pop rdi
        pop rcx
        pop rbx
        ret

player_get_pos:
        ;; returns
        ;; rax = player_x
        ;; rdx = player_y
        xor rax, rax
        mov ax, [player_x]
        xor rdx, rdx
        mov dx, [player_y]
        ret



        section .data
player_x:       dw 0x70         ; 24
player_y:       dw 0x36         ; 136
player_angle:   dw 0x0          ; initial angle of 90
player_half_fov:     dw 0x38         ; player FOV = 112 degrees, we need "half"
