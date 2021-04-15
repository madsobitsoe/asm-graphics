BITS 64
        global _start
        global exitError
        global createBmpBuffer
        extern dyn_writeBmpHeader
        extern writeBmpDataToBuffer
        extern writeBmpBuffer
        extern rectangle
        extern line
        ;; extern cast_ray
        extern draw_rays

_start:                         ;The main entry point of the program
        mov rax, filename
        call openFile
        ;; no. of bytes to allocate should be in rax
        push rax                ; push fd!
        mov rax, 196608         ; total size of pixeldata in bytes
        add rax, 54             ; add header size
        call createBmpBuffer    ; get a buffer for all the data
        mov rbx, 0x100          ; height of image in pixels
        shl rbx, 32
        or rbx, 0x100           ; width of image in pixels
        call dyn_writeBmpHeader
        push rax                ; push start of buffer!
        ;; Now write some fancy rectangles
        ;; Full background
        xchg rax, rdi           ; addr of buffer for rectangle
        add rdi, 54             ; add header size to pointer
        ;; draw the entire buffer
        mov rax, 0x01000100     ; x=0, y=0, width=256, height=256
        mov rbx, 0xAA00FF       ; BGR
        mov rcx, 0x100          ; img_width in pixels
        shl rcx, 32
        or  rcx, 0x100           ; img_height in pixels

        call rectangle
        ;; ;; Now a smaller rectangle
        ;; ;; addr of buf should already be in rsi
        ;; ;; x=128, y=32, width=30, height = 40
        ;; mov rax, 64             ; x
        ;; shl rax, 16
        ;; or  rax, 64             ; y
        ;; shl rax, 16
        ;; or  rax, 128            ; width
        ;; shl rax, 16
        ;; or  rax, 128            ; height
        ;; mov rbx, 0x0            ; color
        ;; mov rcx, 256
        ;; shl rcx, 32
        ;; or  rcx, 256
        ;; call rectangle
        ;; ;; And an even smaller rectangle
        ;; mov rax, 96             ; x
        ;; shl rax, 16
        ;; or  rax, 96             ; y
        ;; shl rax, 16
        ;; or  rax, 64            ; width
        ;; shl rax, 16
        ;; or  rax, 64            ; height
        ;; mov rbx, 0xFFFFFF      ; color
        ;; mov rcx, 256
        ;; shl rcx, 32
        ;; or  rcx, 256
        ;; call rectangle

        ;; ;; Draw a horizontal line!
        ;; mov rax, 0x80           ; x0=0 y0=128
        ;; shl rax, 16
        ;; or  rax, 0x100           ; x1=256
        ;; shl rax, 16
        ;; or  rax, 0x80           ; y1=128
        ;; mov rbx, 0xFF00        ; Green!
        ;; mov rcx, 256
        ;; shl rcx, 32
        ;; or  rcx, 256
        ;; call line
        ;; ;; Draw a vertical line!
        ;; mov rax, 0x80           ; x0=128 y0=0
        ;; shl rax, 32
        ;; or  rax, 0x80           ; x1=128
        ;; shl rax, 16
        ;; or  rax, 0x100           ; y1=256
        ;; mov rbx, 0xFF0000        ; Red!
        ;; mov rcx, 256
        ;; shl rcx, 32
        ;; or  rcx, 256
        ;; call line

        ;; ;; Draw a line that has a slope
        ;; mov  rax, 0x100           ; x0=0, y0=0, x1=256
        ;; shl rax, 0x10
        ;; or  rax, 0x100           ; y1=256
        ;; mov rbx, 0x424344        ; hacky color
        ;; mov rcx, 0x100
        ;; shl rcx, 0x20
        ;; or  rcx, 0x100
        ;; call line


        ;; ;; Draw a line that has a slope
        ;; mov  rax, 0x80           ; x0=0, y0=128
        ;; shl rax, 0x10
        ;; or  rax, 0x100           ; x1=256, y1=192
        ;; shl rax, 16
        ;; or  rax, 192
        ;; mov rbx, 0x424344        ; hacky color
        ;; mov rcx, 0x100
        ;; shl rcx, 0x20
        ;; or  rcx, 0x100
        ;; call line


        ;; ;; Draw a line that has a negative slope
        ;; mov  rax, 0x80           ; x0=0, y0=128
        ;; shl rax, 0x10
        ;; or  rax, 0x90           ; x1=144
        ;; shl rax, 0x10
        ;; or  rax, 0x34           ; y1=132
        ;; mov rbx, 0x424344        ; hacky color
        ;; mov rcx, 0x100
        ;; shl rcx, 0x20
        ;; or  rcx, 0x100
        ;; call line


        ;; ;; Draw a line that has a slope
        ;; mov rax, 0x30           ; x0 = 48
        ;; shl rax, 0x10
        ;; or  rax, 0x30           ; y0 = 48
        ;; shl rax, 0x10
        ;; or  rax, 0x60           ; x1 = 96, y1 = 128
        ;; shl rax, 0x10
        ;; or  rax, 0x80
        ;; mov rbx, 0x424344        ; hacky color
        ;; mov rcx, 0x100
        ;; shl rcx, 0x20
        ;; or  rcx, 0x100
        ;; call line


        ;; ;; ;; Draw a line that has a slope
        ;; ;; mov  rax, 0x80           ; x0=0, y0=0
        ;; ;; shl rax, 0x10
        ;; mov rax, 0xff           ; x1=255
        ;; shl rax, 0x10
        ;; or rax, 0x8F            ; y1=255
        ;; mov rbx, 0xFFFFFF        ; hacky color
        ;; mov rcx, 0x100
        ;; shl rcx, 0x20
        ;; or  rcx, 0x100
        ;; call line

        ;; ;; ;; Draw a line that has a slope
        ;; mov  rax, 0xff           ; x0=0, y0=255
        ;; shl rax, 0x10
        ;; or rax, 0xFF            ; x1=255, y1=0
        ;; shl rax, 0x10
        ;; ;; or rax, 0x10
        ;; mov rbx, 0xFFFFFF        ; hacky color
        ;; mov rcx, 0x100
        ;; shl rcx, 0x20
        ;; or  rcx, 0x100
        ;; call line


        mov rax, 0x80
        shl rax, 16
        or rax, 0x0           ; x0=128 y0=0
        shl rax, 16
        or  rax, 0x80           ; x1=128
        shl rax, 16
        or  rax, 0x100           ; y1=256
        mov rbx, 0xFF00        ; Green!
        mov rcx, 256
        shl rcx, 32
        or  rcx, 256
        call line

        mov rax, 0x80           ; x0=0 y0=128
        shl rax, 16
        or  rax, 0x100           ; x1=256
        shl rax, 16
        or  rax, 0x80           ; y1=128
        mov rbx, 0xFF00        ; Green!
        mov rcx, 256
        shl rcx, 32
        or  rcx, 256
        call line




        ;; Set (x,y) = 128, 128
        ;; increment angle in steps of 16
        ;; cast a ray for each angle with distance = 64
        ;; draw the lines
        ;; push r9
        ;; mov r9, 0               ; start from 0

        mov rax, 64
        shl rax, 32
        or  rax, 64             ;x0=32, y0=32
        mov rbx, 32              ; distance = 32
        shl rbx, 32              ; angle_start = 0
        or  rbx, 360            ; angle_stop = 360
        shl rbx, 16
        or  rbx, 1              ; angle_step
        mov rcx, 0x100
        shl rcx, 32
        or  rcx, 0x100
        call draw_rays

        mov rax, 192
        shl rax, 32
        or  rax, 192             ;x0=32, y0=32
        mov rbx,32              ; distance = 32
        shl rbx,32              ; angle_start = 0
        or  rbx, 360            ; angle_stop = 360
        shl rbx, 16
        or  rbx, 2              ; angle_step
        mov rcx, 0x100
        shl rcx, 32
        or  rcx, 0x100
        call draw_rays

        mov rax, 64
        shl rax, 32
        or  rax, 192             ;x0=32, y0=32
        mov rbx,32              ; distance = 32
        shl rbx,32              ; angle_start = 0
        or  rbx, 360            ; angle_stop = 360
        shl rbx, 16
        or  rbx, 3              ; angle_step
        mov rcx, 0x100
        shl rcx, 32
        or  rcx, 0x100
        call draw_rays

        mov rax, 192
        shl rax, 32
        or  rax, 64             ;x0=32, y0=32
        mov rbx,32              ; distance = 32
        shl rbx,32              ; angle_start = 0
        or  rbx, 360            ; angle_stop = 360
        shl rbx, 16
        or  rbx, 4              ; angle_step
        mov rcx, 0x100
        shl rcx, 32
        or  rcx, 0x100
        call draw_rays


        mov rax, 128
        shl rax, 32
        or  rax, 128             ;x0=32, y0=32
        mov rbx,64              ; distance = 64
        shl rbx,32              ; angle_start = 0
        or  rbx, 360            ; angle_stop = 360
        shl rbx, 16
        or  rbx, 15              ; angle_step
        mov rcx, 0x100
        shl rcx, 32
        or  rcx, 0x100
        call draw_rays




        ;; Now save it!
        ;; fd should be in rax
        ;; size of buffer in rdx
        ;; addr of buffer in rsi
        pop rsi                 ;addr of buffer
        pop rax                 ; fd
        mov rdx, 196608
        add rdx, 54             ;add header size
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
