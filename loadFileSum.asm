section .data
    fileName db "randomInt100.txt", 0  
    errorMsg db "Error: File not found!", 10
    errorLen equ $ - errorMsg
    newline db 10

section .bss
    fileHandle resd 1
    fileBuffer resb 1024  
    sum resd 1           
    buffer resb 16        

section .text
global _start
_start:
    mov dword [sum], 0

    ; Open file
    mov eax, 5         
    mov ebx, fileName   
    mov ecx, 0         
    int 0x80

    ; testing for existing file
    test eax, eax
    js error_exit    
    mov [fileHandle], eax

    ; Read file
    mov ebx, eax      
    mov eax, 3          
    lea ecx, [fileBuffer]
    mov edx, 1024       
    int 0x80

    ; exits if read fails or empty file
    test eax, eax
    jle close_file      

    ; Process buffer to calculate sum
    mov esi, fileBuffer  
    mov ecx, eax         
    xor eax, eax         

parse_loop:
    cmp ecx, 0           ; Prevent buffer overrun
    jle finalize_sum

    movzx ebx, byte [esi] ; Get current #
    inc esi
    dec ecx              ;  counter--

    cmp ebx, 10          ; Check for newline
    je add_number

    sub ebx, '0'         ; Convert ASCII to integer
    cmp ebx, 0
    ; Skip invalid characters
    jl parse_loop        
    cmp ebx, 9
    jg parse_loop       

    imul eax, 10         ; Multiply current number by 10
    add eax, ebx         ; Add new digit
    jmp parse_loop

add_number:
    ; adding up # on each line
    add [sum], eax      
    xor eax, eax         
    jmp parse_loop

finalize_sum:
    test eax, eax        ; Add last number if no newline at end
    jz convert_sum
    add [sum], eax

convert_sum:
    ; convert # from binary to ascii
    mov eax, [sum]
    mov edi, buffer + 15  
    mov byte [edi], 10   
    dec edi

    mov ecx, 10        

convert_loop:
    ; convert # from ascii
    xor edx, edx
    div ecx              
    add dl, '0'          
    mov [edi], dl        
    dec edi
    test eax, eax
    jnz convert_loop

    ; Print sum
    mov ecx, edi
    inc ecx              
    mov edx, buffer + 16
    sub edx, ecx         ; adding sum
    mov eax, 4
    mov ebx, 1
    int 0x80

close_file:
    ; Close file
    mov eax, 6        
    mov ebx, [fileHandle]
    int 0x80

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; error case
error_exit:
    mov eax, 4
    mov ebx, 1
    mov ecx, errorMsg
    mov edx, errorLen
    int 0x80
    jmp exit
