        ;; Create bmp files from assembly
        global dyn_writeBmpHeader
        global writeBmpDataToBuffer
        global rectangle
        global line
        global draw_pixel
        global writeBmpBuffer
        global draw_rays
        extern exitError
        extern cast_ray
        extern check_bounds
        extern clamp
        BITS 64

;; Dynamically generate a valid BMP header and write it file at fd
dyn_writeBmpHeader:
        ;; Preconds:
        ;; addr of buffer to write header in should be in rax
        ;; height << 32 | width of image in rbx
        ;; postcond:
        ;; 54-byte bmp-header is written to the buffer pointed to by addr in rax
        push rbx                ; store height << 32 | width on stack
        push rax                ;store addr on stack
        ;; Compute size of file in bytes
        mov rax, rbx
        shr rax, 32
        mov ecx, eax            ; width of img in pixels (for header)
        shl rbx, 32
        shr rbx, 32
        mov edx, ebx            ; height of img in pixels (for header)
        mul rbx
        mov rbx, 3
        mul rbx
        mov ebx, eax            ; rbx has size of file (which can only be 4 bytes large)
        mov rdi,0x4d42          ;"BM"
        add rbx, 54             ; add header size to byte count
        shl rbx, 16
        or rbx, rdi
        pop rax                 ; rax has addr
        mov [rax], rbx          ; write "BM" + size in bytes
        mov dword [rax+6], 0x0 ; useless 4 byte field + offset into data
        mov dword [rax+10], 0x36
        mov dword [rax+14], 0x28        ; size of info-header = 40
        pop rcx
        mov qword [rax+18], rcx         ; width and height in pixels
        mov dword [rax+26], 0x00180001  ; no. of planes + bpp
        mov qword [rax+30], 0                 ; 8 0-bytes (compression used)
        mov qword [rax+38], 0                 ; horizontal/vertical resolution - just zero
        mov qword [rax+46], 0                 ; colors used + all colors are important
        ;; colors used = 0 default to 2^n
        ret



writeBmpDataToBuffer:
        ;; Preconds:
        ;; buf_addr should be in rax
        ;; bmpwidth should be in rdi
        ;; bmpheight should be in rdx
        ;; Postconds:
        ;; width * height black pixels written to fd
        push rax                ;store addr on stack
        mov rax, rdi            ; put width in rax
        imul rdx                ; multiply by height
        mov rdx, 3              ; mov 3 to rdx to multiply
        imul rdx                  ; multiply by num of pixels, to get total bytes
        pop rdx                   ; pop addr into rdx
writeBmpDataToBuffer_chk:
        cmp rax, 0
        jg writeBmpDataToBuffer_loop
        ret                     ; return if done
writeBmpDataToBuffer_loop:
        ;;  This only updates the counter
        ;; need to grab the pointer instead of inc'ing it

        mov [rdx], byte 0xff
        inc rdx
        mov [rdx], byte 0x00
        inc rdx
        mov [rdx], byte 0xff
        inc rdx
        sub rax, 3
        jmp writeBmpDataToBuffer_chk


writeBmpBuffer:
        ;; Preconds:
        ;; fd should be in rax
        ;; size of buffer should be in rdx
        ;; addr of buf should be in rsi
        ;; postcond:
        ;; bmp-buffer is written to the file pointed to by fd in rax
        ;; remarks:
        ;; Potentially overwrites rax,rdi,rdx,r8,r9,r10
        ;; writes to a file
        push rax                ; store fd on stack
        xchg rax, rdi           ; fd in rdi
        mov rax, 1              ; syscall for write
        syscall
        pop rax
        ret




draw_pixel:
        ;; preconds
        ;; addr of buf should be in rdi
        ;; x  should be in rax
        ;; y should be in rdx
        ;; color as r << 16 | g << 8 | b should be in rbx
        ;; img_width,img_height (in pixels) as img_width << 32 | img_height should
        ;; be in rcx
        push rax
        push rcx
        push rbx
        push rdx
        push rsi
        ;; check bounds
        push rax
        call check_bounds       ;check bounds
        cmp rax, -1
        je draw_pixel_exit_error ; if error, fail silently by not drawing
        pop rax
        mov rsi, rdx
        shr rcx, 32             ; width
        xchg rax, rsi
        mul rcx
        mov rcx, 3
        mul rcx                 ; byte-width of img * y in rax
        xchg rax,rsi
        mul rcx                 ; byte-offset for x-coord
        add rax, rsi            ; real offset for pixel
        add rax, rdi            ; real location for pixel
draw_pixel_write:
        mov byte [rax], bl
        shr rbx, 8
        mov byte [rax+1], bl
        shr rbx, 8
        mov byte [rax+2], bl
        jmp draw_pixel_exit
draw_pixel_exit_error:
        pop rax
draw_pixel_exit:
        pop rsi
        pop rdx
        pop rbx
        pop rcx
        pop rax
        ret


line:
        ;; preconds
        ;; addr of buf should be in rdi
        ;; (x0,y0), (x1,y1) should be in rax as
        ;; x0 << 48 | y0 << 32 | x1 << 16 | y1
        ;; color as r << 16 | g << 8 | b should be in rbx
        ;; img_width,img_height (in pixels) as img_width << 32 | img_height should be in rcx
        ;; remarks:
        ;; Uses the midpoint-algorithm to draw a rasterized line
        push rdx
        push rdi                ; put addr on stack
        push rbx                ; put color on stack
        push rcx                ; put img_width,img_height on stack
        push rax                ; put coords on stack

        ;; Clamp the coords!
line_clamp:
        push rdi
        push rdx
        push rax
        shr rax, 32
        xor rdx, rdx
        mov dx, ax              ; y0
        shr rax, 16             ; x0
        call clamp
        mov rdi, rax            ; x0 in rdi
        shl rdi, 16             ; x0 << 16 in rdi
        or  rdi, rdx            ; x0 << 16 | y0
        shl rdi, 32             ; x0 << 48 | y0 << 32
        pop rax
        mov rdx, rax
        shl rax, 32
        shr rax, 48             ; x1
        shl rdx, 48
        shr rdx, 48             ; y1
        call clamp
        shl rax, 16
        or rax, rdx
        or rax, rdi
        pop rdx
        pop rdi

        ;; Ensure we are always drawing from left to right!
line_ensure_left_right:
        mov rbx, rax
        shr rbx, 48             ;x0
        shl rax, 32
        shr rax, 48             ;x1
        cmp rbx, rax
        jle line_draw_line
        ;; jl line_check_if_horizontal
        ;; je line_vertical_rect
line_swap_coords:
        pop rax                 ; x0,y0,x1,y1
        mov rbx, rax            ; copy to rbx
        shr rax, 32             ; x0, y0
        shl rbx, 32             ; x1, y1
        or rax, rbx             ; x1,y1,x0,y0
        push rax
        ;; ADDED DEBUG
        jmp line_draw_line
        ;; If this is a straight line, we can use the rectangle function instead
line_check_if_horizontal:
        mov rax, [rsp]          ;get coords back in rax
        mov rbx, rax
        shl rax, 16
        shr rax, 48             ;y0
        and rbx, 0xFFFF         ;y1
        cmp rbx, rax
        je line_horizontal_rect

        ;; After all the checks, finally draw a line!
line_draw_line:
        mov rax, [rsp]   ; x1
        shl rax, 32
        shr rax, 48
        mov r13, rax            ; r13 == x1
        mov rbx, [rsp]     ; x0
        shr rbx, 48
        sub rax, rbx            ; x1 - x0 == dx
        shl rax, 1              ; abs_2dx -- We KNOW that x0 < x1, always positive
        mov rcx, 0
        mov rdx, 0
        mov rcx, [rsp]
        and rcx, 0xFFFF        ; y1
        mov r14, rcx           ; y1 == r14
        mov rdx, [rsp]
        shl rdx, 16
        shr rdx, 48             ; y0
        ;; dy
        sub rcx, rdx            ; dy
        ;; mov rdx, rcx
        ;; sar rdx, 63
        ;; xor rcx, rdx
        ;; ;; absolute value of dy
        ;; sub rcx, rdx            ; abs(dy)
        mov rsi, 1              ; initial value for y_step
        cmp rcx, 0            ; is dy < 0
        jge line_draw_line_dy_positive ; if not, draw with y_step=1
        mov rsi, -1             ; else, y_step is negative
        ;; ;; old code
        ;; mov rsi, 1              ; initial value for y_step
        ;; cmp rcx, rdx            ; is y1>y0 ?
        ;; jg line_draw_line_dy_positive
        ;; xchg rcx, rdx           ; if not, swap them (for computation of abs value)
        ;; mov rsi, -1             ; y_step is negative
line_draw_line_dy_positive:
        mov rdx, rcx
        neg rcx
        cmovl rcx, rdx                 ; abs(dy)
        ;; sub rcx, rdx            ; |y1 - y0|
        shl rcx, 1              ; abs_2dy
        ;;  Ensure actual y is in rdx
        mov rdx, [rsp]
        shl rdx, 16
        shr rdx, 48             ; y0
        ;; Is this x-dominant or y-dominant?
        cmp rax, rcx
        jg line_x_dom_init
        jmp line_y_init

line_x_dom_init:
        mov r8, rcx             ; abs_2dy in r8
        shr rax, 1
        sub r8, rax            ; d = abs_2dy - (abs_2dx >> 1)
        shl rax, 1              ; restore abs_2dx
line_x_dom_loop:
        cmp rbx, r13            ; Are we done?
        je line_exit
        cmp r8, 0
        jl line_x_dom_loop_skip_y_inc
        add rdx, rsi            ; y += y_step
        sub r8, rax            ; d -= abs_2dx
line_x_dom_loop_skip_y_inc:
        inc rbx                 ; x += x_step
        add r8, rcx            ; d += abs_2dy
        ;; (rbx,rdx) == (x,y)
        mov r9, rbx
        mov r11, rax
        mov rax, rbx
        mov rbx, [rsp+16]
        mov r10, rcx
        mov rcx, [rsp+8]
        call draw_pixel
        mov rcx, r10
        mov rbx, r9
        mov rax, r11
        jmp line_x_dom_loop

line_y_init:
        mov r8, rax             ; abs_2dx
        shr rcx, 1              ; abs_2dy >> 1
        sub r8, rcx             ; d = abs_2dx - (abs_2dy >> 1)
        shl rcx, 1              ; restore abs_2dy
line_y_dom_loop:
        cmp rdx, r14            ; Are we done? y >= y1
        je line_exit
        cmp r8, 0               ; if (d >= 0)
        jl line_y_dom_loop_skip_x_inc
        inc rbx                 ; x += x_step
        sub r8, rcx             ; d -= abs_2dy
line_y_dom_loop_skip_x_inc:
        add r8, rax             ; d += abs_2dx
        add rdx, rsi             ; y += y_step
        ;; (rbx,rdx) == (x,y)
        mov r9, rbx
        mov r11, rax
        mov rax, rbx
        mov rbx, [rsp+16]
        mov r10, rcx
        mov rcx, [rsp+8]
        call draw_pixel
        mov rcx, r10
        mov rbx, r9
        mov rax, r11
        jmp line_y_dom_loop

        jmp line_exit


line_exit:
        pop rax
        pop rcx
        pop rbx
        pop rdi
        pop rdx
        ret

line_vertical_rect:
        pop rax                 ;coords
        mov rbx, 0xFFFFFFFF0000FFFF     ; mask for x1, which needs to be 1 now
        and rax, rbx
        or rax, 0x10000         ; set width to 1
        mov ebx, 0
        mov bx, ax              ; y1
        mov rcx, rax
        shl rcx, 16
        shr rcx, 48             ; y0
        cmp rbx, rcx            ; is y1 > y0?
        jg line_height_is_fine
        je line_error           ;no height, no vertical line
        ;; Else, swap y0 and y1
        mov rdx, 0xFFFF0000FFFF0000
        and rax, rdx
        shl rbx, 32
        or  rcx, rbx
        or  rax, rcx
        shr rbx, 32
        xchg rbx, rcx
line_height_is_fine:
        sub rbx, rcx
        ;; Clear out y1 in coord - to replace with height
        shr rax, 16
        shl rax, 16
        or rax, rbx
        jmp line_use_rectangle
line_horizontal_rect:
        pop rax                 ;coords
        ;; Compute width of line, x1-x0
        mov ebx, eax
        shr rbx, 16             ; x1
        mov rcx, rax
        shr rcx, 48             ; x0
        sub rbx, rcx
        shl rbx, 16
        ;; clear out width-param
        mov rdx, 0xFFFFFFFF0000FFFF
        and rax, rdx
        or  rax, rbx            ; and write the correct value
        ;; clear out y1, to replace with 1
        shr rax, 16
        shl rax, 16
        or  rax, 1
line_use_rectangle:
        pop rcx
        pop rbx
        pop rdi
        call rectangle
        pop rdx
        int3
        ;; jmp rectangle
        ret

line_error:
        ;; just return - definitely don't draw anything
        ;; pop rax
        int3
        pop rcx
        pop rbx
        pop rdi
        pop rdx
        ret


rectangle:
        ;; preconds
        ;; addr of buf should be in rdi
        ;; top-left x,y,width,height should be in rax as x << 48 | y << 32 | width << 16 | height
        ;; color as r << 16 | g << 8 | b should be in rbx
        ;; img_width,img_height (in pixels) as img_width << 32 | img_height should be in rcx
        ;; postconds - rectangle of color written to buf in rdi

        ;; compute total bytes to write - width x height x 3 (assume no padding for bmp)

        ;; save all callee-save registers
        push rbp
        push rbx
        push r12
        push r13
        push r14
        push r15
        push rax                ; save input coords on stack
        push rbx                ; save color on stack
        push rdi                ; addr of buf
        mov r11, rdi            ; addr for computations
        mov r10, rax            ; save input-coords in r10 (for easy access)
        ;; Compute byte-width of image
        mov r8, 3
        shr rcx, 32
        mov rax, rcx
        mul r8
        mov rbp, rax            ;store byte-width of image in rbp
        ;; mov r8, rax
        mov rax, r10
        and eax, 0xffff0000     ; get width of rectangle
        shr rax, 16
        mov r8, 3               ;bytes per line
        mul r8
        mov r12, rax            ; save the byte-width in a register
        mov rax, r10
        and rax, 0xffff          ; get height of rectangle
        mov r13, rax             ; save the height in a register
        mul r12                  ; width * height
        mov r9, rax             ;store total bytes to write

        ;; Compute starting offset into buf
        mov rax, r10
        shl rax, 16             ; remove topleft-x
        shr rax, 48             ; grab topleft-y
        mov rbx, rax            ; current y
        mov rax, r10
        shr rax, 48             ; topleft x
        mul r8                  ; times 3 because 3 bytes per pixel
        add rax, r11            ; current x (and base x-offset) (r11 has address)
        mov rcx, rax            ; store base x-offset
        ;; Now add x + y * byte-width of image
        mov rax, rbx            ; current y in rax
        mul rbp                 ; multiply by byte-width of line
        add rax, rcx            ; add x-offset
        xor r14, r14            ; bytes written so far - per row
rectangle_loop:
        cmp r14,r12             ; have we written all bytes in this row?
        jl rectangle_write
        ;; if we are done with this row, check if we're completely done
        inc rbx                 ; increment y
        dec r13                 ; one less row to write
        cmp r13, 0
        jle rectangle_exit
        ;; else, increment y and compute index to write next row

        mov rax, rbx            ; current y in rax
        mul rbp                 ; multiply by byte-width of img
        add rax, rcx            ; add base x-offset
        mov r14, 0              ;and reset byte-count for line
rectangle_write:
        mov rdx, [rsp+8]       ; color
        mov byte [rax], dl
        shr rdx, 8
        mov byte [rax+1], dl
        shr rdx, 8
        mov byte [rax+2], dl
        add rax, 3
        add r14, 3
        jmp rectangle_loop

rectangle_exit:
        pop rdi
        pop rbx
        pop rax
        ;; restore calles-save regs
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp
        ret


draw_rays:
        ;; draws rays from x0,y0 with distance c and angle a
        ;; x0 << 32 | y0 in rax
        ;; distance << 16 | angle_start << 32 | angle_stop << 16 | angle_step in rbx
        ;; buf in rdi
        ;; img_width << 32 | img_height in rcx
        push r8
        push r9
        push r10
        push r11
        push rax
        push rbx
        push rcx
        push rdi
        push rsi
        mov r8, rbx
        shr r8, 48              ; distance
        mov r9, rbx
        shl r9, 16
        shr r9, 48              ; angle_start (current angle)
        mov r10d, ebx

        shr r10, 16             ; angle_stop
        mov r11, rbx
        and r11, 0xffff         ; angle_step
ray_loop:
        cmp r9, r10
        jge ray_loop_exit

        mov rax, [rsp+32]       ; x,y

        mov rbx, r8             ; distance
        shl rbx, 32
        or rbx, r9              ; current angle
        push r8
        push r9
        push r10
        push r11
        call cast_ray
        pop r11
        pop r10
        pop r9
        pop r8
        ;; Color goes in rbx
        mov rbx, 0xAAFF00
        ;; img_width << 32 | img_height should be in rcx
        mov rcx, [rsp+16]
        mov rdi, [rsp+8]
        push r8
        push r9
        push r10
        push r11
        call line
        pop r11
        pop r10
        pop r9
        pop r8
        add r9, r11
        jmp ray_loop
ray_loop_exit:
        pop rsi
        pop rdi
        pop rcx
        pop rbx
        pop rax
        pop r11
        pop r10
        pop r9
        pop r8
        ret
