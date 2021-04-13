        ;; Create bmp files from assembly

        global _start

        BITS 64
_start:                         ;The main entry point of the program
        mov rax, filename
        call openFile
        ;; call writeBmpHeader
        ;; no. of bytes to allocate should be in rax
        push rax                ; push fd!
        mov rax, 196608
        add rax, 54             ; add header size
        call createBmpBuffer
        mov rbx, 0x100
        shl rbx, 32
        or rbx, 0x100
        call dyn_writeBmpHeader
        push rax                ; push start of buffer!
        add rax, 54             ;add header size to pointer
        ;; Preconds:
        ;; buf_addr should be in rax
        ;; bmpwidth should be in rdi
        ;; bmpheight should be in rdx
        push rax
        push rdi
        push rdx
        mov r9, rax             ; store addr
        mov rdi, 0x100
        mov rdx, 0x100
        call writeBmpDataToBuffer
        pop rdx
        pop rdi
        pop rax
        mov rax, r9
        ;; addr of buf should be in rsi
        mov rsi, r9
        ;; fd should be in rax
        pop rax
        ;; size of buffer should be in rdx
        mov rdx, 196608
        add rdx, 54             ;add header size
        push rax
        push rdx
        push rsi
        push rdi
        mov rdi, rsi
        ;; x=128, y=32, width=30, height = 40
        mov rax, 64             ; x
        shl rax, 16
        or  rax, 64             ; y
        shl rax, 16
        or  rax, 128            ; width
        shl rax, 16
        or  rax, 128            ; height
        mov rbx, 0x0            ; color
        mov rcx, 256
        shl rcx, 32
        or  rcx, 256
        push rdi
        call rectangle
        pop rdi
        mov rax, 96             ; x
        shl rax, 16
        or  rax, 96             ; y
        shl rax, 16
        or  rax, 64            ; width
        shl rax, 16
        or  rax, 64            ; height
        mov rbx, 0xFFFFFF      ; color
        mov rcx, 256
        shl rcx, 32
        or  rcx, 256
        call rectangle
        pop rdi
        pop rsi
        pop rdx
        pop rax
        mov rsi, rax
        pop rax
        mov rdx, 196608
        add rdx, 54             ;add header size

        ;; fd should be in rax
        ;; size of buffer in rdx
        ;; addr of buffer in rsi
        call writeBmpBuffer
        call closeFile
        jmp exitSuccess

openFile:
        ;; Precond for openfile
        ;; pointer to filename should be in rax
        ;; Postcond: Filedescriptor will be returned in rax
        ;; Remarks
        ;; Uses syscall, so rax, rsi, rdi, r8, r9, r10 might be overwritten
        mov rdi, rax            ; pointer to filename goes in rdi
        mov rax, 2              ; syscall for open
        mov rsi, 1              ; write_only flag
        or  rsi, 64              ; or with O_CREAT
        or  rsi, 512              ; or with O_TRUNC
        mov rdx, 0x1b8          ; Set the mode to 0x666 (which then sets permission for new file
        ;; mov rdx, 0
        ;; as mode & ~umask - hope that umask is 022
        syscall
        ;; Handle errors!
        cmp rax, 0
        jl exitError           ;Something went wrong. Exit gracefully with errno
        ret                     ; return to calling function (lol, label). fd is in rax


closeFile:
        ;; Preconds:
        ;; fd should be in rax
        ;; postcond:
        ;; fd is closed
        ;; remarks:
        ;; Potentially overwrites rax,rdi,rdx,r8,r9,r10
        mov rdi, 3              ;syscall for close
        xchg rax,rdi            ; put fd in rdi, syscall no. in rax
        syscall
        cmp rax,0               ;Check for errors
        jl exitError            ;exit with errno from syscall if error
        ret                     ; else, return

writeBmpHeader:
        ;; Preconds:
        ;; fd should be in rax
        ;; postcond:
        ;; bmp-header is written to the file pointed to by fd in rax
        ;; remarks:
        ;; Potentially overwrites rax,rdi,rdx,r8,r9,r10
        ;; writes to a file
        push rax                ;store fd on stack
        xchg rax, rdi           ; fd in rdi
        mov rax, 1              ; syscall for write
        mov rdx, 54;; bmp_fhdr_sz
                                ; write "size of bmp-header" bytes
        mov rsi, bmp_hdr_header
        syscall
        pop rax
        ret

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
        ;; and rbx, 0xFFFFFFFF
        mov edx, ebx            ; height of img in pixels (for header)
        mul rbx
        mov rbx, 3
        mul rbx
        ;; add rax, 54             ; add size of header
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
        mov qword [rax+18], rcx         ; width in pixels
        ;; mov dword [rax+22], edx         ; height in pixels
        mov dword [rax+26], 0x00180001  ; no. of planes + bpp
        mov qword [rax+30], 0                 ; 8 0-bytes (compression used)
        mov qword [rax+38], 0                 ; horizontal/vertical resolution - just zero
        mov qword [rax+46], 0                 ; colors used + all colors are important
        ;; colors used = 0 default to 2^n

        ret




createBmpBuffer:
        ;; MMAP a buffer for storing bmp data
        ;; Preconds
        ;; no. of bytes to allocate should be in rax
        ;; postconds
        ;; On success, address is returned in rax
        ;; on error, exits with errno from syscall
        ;; remarks:
        ;; Overwrites rax,rdi,rdx, r8,r9,r10
        ;; Reserves memory in readwrite mode
        mov rsi, 9               ;syscall for mmap
        xchg rax, rsi            ;put num of bytes to allocate in rsi, syscall num in rax
        xor rdi,rdi             ; we don't care where the memory is. let the kernel decide
        mov rdx, 3              ; PROT_READ | PROT_WRITE
        ;; We don't want to map to the file we created, as we want to overwrite the file entirely if it existed
        mov r10, 0x22              ; MAP_PRIVATE | MAP_ANONYMOUS - no file backing
        mov r8, -1               ; -1 for fd. (optional, good practice)
        xor r9, r9              ; no offset!
        syscall                 ; map the area
        cmp rax, 0              ; check for errors
        jl exitError            ; exit with errno from syscall
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

exitError:
        ;; Figure out what the error was
        neg rax
        mov rdi, rax
        jmp exit
exitSuccess:
        mov     rdi, 0           ; return value for exit syscall success
exit:
        mov     rax, 60         ; syscall for exit
        syscall                 ; exit successfully



        section .data
        ;; vars for my file
filename:       db "test.bmp",0
bmp_width       equ 0x100
bmp_height      equ 0x100
        ;; Vars for the BMP format
bmp_fhdr_sz equ 14              ;bitmap file header


        ;; Vars for the bitmap header
bmp_hdr_header: db "BM"         ; 2-byte "magic number" for bmp
bmp_hdr_sz_fld: dd 0x30036              ; size of the bmp file in bytes - 0xa * 0x14 * 0x3 + 0xe
bmp_hdr_useless_fld: dd 0x00000000
bmp_hdr_offset: dd 0x36         ; offset to data is 14 byte hdr + 40 bytes info-header
info_hdr_sz:    dd 0x28   ; size of info header == 40
info_hdr_width: dd 0x100   ; width of img in pixels for info header
info_hdr_height: dd 0x100   ; height of img in pixels for info header
info_hdr_planes:        dw 0x1 ;number of planes == 1
info_hdr_bpp:   dd 0x18         ;24 bits per pixel, 24bit RGB
info_hdr_comp:  dd 0x00000000     ;no compression
info_hdr_imgsz: dd 0x00000000     ;compressed size of img is 0, because no compression
info_hdr_xppm:  dd 0x00000000     ; Horizontal resolution, pixels/meter
info_hdr_yppm:  dd 0x00000000     ; Vertical resolutin, pixels/meter
info_hdr_colors_used:   dd 0x0 ; actual number of colors used
info_hdr_imp_col:       dd 0x0 ; all colors are important
