bits    64
global decomposition_asm
section .text
decomposition_asm:
    ; rdi - from 
    ; rsi - to
    ; rdx - width
    ; rcx - height
    ; r8 - mode
    push r12
    push r13
    push rbx
    mov r12, rdi    ; сохранили источник
    mov r13, rsi    ; сохранили результат
    mov rax, rdx
    mul rcx   ; посчитали количество пикселей в rax
    mov r10, rax    ; сохранили width * height в r10
    test r10, r10
    jz .end

.loop:
    ; находим R, G, B
    movzx eax, byte[r12]  ; eax = R
    movzx ebx, byte[r12 + 1]  ; ebx = G
    test r8, r8
    jnz .max3

; если mode = 0, ищем min
.min3:
    cmp eax, ebx
    cmovg eax, ebx      ; eax = min(R, G)
    movzx ebx, byte[r12 + 2]  ; ebx = B
    cmp eax, ebx    
    cmovg eax, ebx      ; eax = min(min(R, G), B)
    jmp .put

; если mode = 1, ищем max
.max3:
    cmp eax, ebx
    cmovl eax, ebx      ; eax = max(R, G)
    movzx ebx, byte[r12 + 2]  ; ebx = B
    cmp eax, ebx    
    cmovl eax, ebx      ; eax = max(min(R, G), B)
    
.put:
    mov byte[r13], al
    movzx ebx, byte[r12 + 3]
    mov byte[r13 + 1], bl
    add r12, 4
    add r13, 2
    dec r10
    jnz .loop
    
.end:
    pop rbx
    pop r13
    pop r12
    ret