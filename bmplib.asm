        ;; Create bmp files from assembly
        global dyn_writeBmpHeader
        global writeBmpDataToBuffer
        global rectangle
        global writeBmpBuffer
        extern exitError
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



rectangle:
        ;; preconds
        ;; addr of buf should be in rdi
        ;; top-left x,y,width,height should be in rax as x << 48 | y << 32 | width << 16 | height
        ;; color as b << 16 | r << 8 | g should be rbx
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
        cmp r13, 0
        jle rectangle_exit
        ;; else, increment y and compute index to write next row
        inc rbx                 ; increment y
        dec r13                 ; one less row to write
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
