        ;; Create bmp files from assembly

        global _start

        BITS 64
_start:                         ;The main entry point of the program
        mov rax, filename
        call openFile
        call writeBmpHeader
        ;; no. of bytes to allocate should be in rax
        push rax
        mov rax, 600
        call createBmpBuffer
        ;; Preconds:
        ;; buf_addr should be in rax
        ;; bmpwidth should be in rdi
        ;; bmpheight should be in rdx
        mov r9, rax             ; store addr
        mov rdi, 0x8
        mov rdx, 0x8
        call writeBmpDataToBuffer
        mov rax, r9
        ;; addr of buf should be in rsi
        mov rsi, r9
        ;; fd should be in rax
        pop rax
        ;; size of buffer should be in rdx
        mov rdx, 600
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
bmp_width       equ 0x8
bmp_height      equ 0x8
        ;; Vars for the BMP format
bmp_fhdr_sz equ 14              ;bitmap file header


        ;; Vars for the bitmap header
bmp_hdr_header: db "BM"         ; 2-byte "magic number" for bmp
bmp_hdr_sz_fld: dd 0xf6              ; size of the bmp file in bytes - 0xa * 0x14 * 0x3 + 0xe
bmp_hdr_useless_fld: dd 0x00000000
bmp_hdr_offset: dd 0x36         ; offset to data is 14 byte hdr + 40 bytes info-header
info_hdr_sz:    dd 0x28   ; size of info header == 40
info_hdr_width: dd 0x8   ; width of img in pixels for info header
info_hdr_height: dd 0x8   ; height of img in pixels for info header
info_hdr_planes:        dw 0x1 ;number of planes == 1
info_hdr_bpp:   dd 0x18         ;24 bits per pixel, 24bit RGB
info_hdr_comp:  dd 0x00000000     ;no compression
info_hdr_imgsz: dd 0x00000000     ;compressed size of img is 0, because no compression
info_hdr_xppm:  dd 0x00000000     ; Horizontal resolutin, pixels/meter
info_hdr_yppm:  dd 0x00000000     ; Vertical resolutin, pixels/meter
info_hdr_colors_used:   dd 0x0 ; actual number of colors used
info_hdr_imp_col:       dd 0x0 ; all colors are important
