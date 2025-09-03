bits    64
section .data
    x_prompt db "Введите x: ", 0
    eps_prompt db "Введите точность: ", 0
    input_format db "%lf", 0
    file_format db "n=%d : %.15lf : diff=%.10lf", 10, 0

    libm_format db "sh(x) через libm (exp)  = %.15lf", 10, 0
    sinh_format db "sh(x) через libm (sinh) = %.15lf", 10, 0
    sum_format db  "sh(x) через ряд         = %.15lf", 10, 0
    
    n dd 0  ; счетчик членов ряда
    current dq 0.0  ; текущий член ряда
    prev    dq 0.0  ; предыдущий член ряда (для проверки точности)
    diff    dq 0.0  ; разница между членами


    two dq 2.0
    file_mode db "w", 0

    error_input db "Некорректный ввод.", 10, 0
    error_dialog db "Введено больше 1 числа.", 10, 0
    error_arguments db "Формат ввода: %s <имя_файла>", 10, 0
    open_failed db "Не удалось открыть файл <%s>", 10, 0



section .bss
    x   resq 1  ; хранит введенное значение
    res resq 1  ; хранит результат 
    res_libm resq 1 ; хранит результат через exp
    res_sum resq 1  ; хранит текущий результат через ряд
    eps resq 1  ; хранит точность

    inter1 resq 1   ; для промежуточных результатов
    square_x resq 1 ; x^2

    file_d resq 1   ; файловый дескриптор 

section .text
global main

extern printf
extern scanf
extern exp
extern sinh
extern exit
extern fabs
extern fopen
extern fprintf
extern fclose
extern getchar


main:
    ; выравнивание
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; проверяем количество аргументов
    cmp rdi, 2
    jb args_error

.open_file:
    ; открываем файл
    add rsi, 8
    mov rdi, [rsi]
    mov rsi, file_mode
    call fopen
    test rax, rax
    jz open_error
    mov [file_d], rax   ; сохранили дескриптор

.dialog:
    ; Получаем число x
    mov rdi, x_prompt
    xor eax, eax
    call printf
    mov rdi, input_format
    mov rsi, x
    xor eax, eax
    call scanf

    cmp eax, -1
    je end
    cmp eax, 1
    jne input_error

    ; чистим буфер
    call clear_buffer


    ; Получаем точность eps
    mov rdi, eps_prompt
    xor eax, eax
    call printf
    mov rdi, input_format
    mov rsi, eps
    xor eax, eax
    call scanf

    cmp eax, -1
    je end
    cmp eax, 1
    jne input_error

    ; чистим буфер
    call clear_buffer
    

expon:
; Считаем sh(x) = (e^x - e^-x) / 2 
    movsd xmm0, [x]
    call exp        ; e^x в xmm0
    movsd [inter1], xmm0  ; e^x в xmm1
    
    xorpd xmm0, xmm0
    subsd xmm0, [x]
    call exp        ; e^-x в xmm0

    movsd xmm1, [inter1]
    subsd xmm1, xmm0    ; в xmm1 (e^x - e^-x)

    divsd xmm1, [two]   ; (e^x - e^-x) / 2

    ; Вывод результата через экспоненту
    movsd [res_libm], xmm1
    mov rdi, libm_format
    movsd xmm0, [res_libm]
    mov eax, 1
    call printf
shin:
    movsd xmm0, [x]
    call sinh
    mov rdi, sinh_format
    mov eax, 1
    call printf

row:
    movsd xmm0, [x]
    movsd [current], xmm0   ; первый (n=0) член = x
    mov dword [n], 0        ; начальный индекс ряда

    mulsd xmm0, xmm0    ; считаем x^2
    movsd [square_x], xmm0

.loop:
    ; Обновляем сумму
    movsd xmm0, [res_sum]
    addsd xmm0, [current]
    movsd [res_sum], xmm0
    
    ; проверяем точность
    cmp dword [n], 0
    je .update_sum  ; если первый член - не надо проверять

    ; смотрим разницу между текущим и предыдущим членами
    movsd xmm0, [prev]
    subsd xmm0, [current]
    call fabs
    movsd [diff], xmm0
    comisd xmm0, [eps]
    jb .end_loop

.update_sum:

    ; записываем член ряда в файл
    mov rdi, [file_d]
    mov rsi, file_format
    mov rdx, [n]
    movsd xmm0, [current]
    movsd xmm1, [diff]
    mov eax, 2
    call fprintf

    ; вычисляем следующий член: current * x^2 / [2n*(2n+1)]
    ; 1) увеличиваем n
    mov ecx, [n]
    inc ecx
    mov [n], ecx

    ; 2) находим 2n*(2n+1)
    imul ecx, 2     ; в ecx 2*n
    mov eax, ecx 
    inc eax 
    imul eax, ecx   ; в eax 2n*(2n+1)

    cvtsi2sd xmm1, eax  ; преобразуем из целого в вещественное
    movsd [inter1], xmm1
    
    ; 3) расчет члена ряда
    movsd xmm0, [current]
    movsd [prev], xmm0      ; сохранили прошлый член 
    mulsd xmm0, [square_x]
    divsd xmm0, [inter1]
    movsd [current], xmm0

    jmp .loop

.end_loop:
    ; записываем последний член в файл
    mov rdi, [file_d]
    mov rsi, file_format
    mov rdx, [n]
    movsd xmm0, [current]
    movsd xmm1, [diff]
    mov eax, 2
    call fprintf

    ; печатаем результат вычисления ряда
    mov rdi, sum_format
    movsd xmm0, [res_sum]
    mov eax, 1
    call printf

.close_file:
    ; закрываем файл
    mov rdi, [file_d]
    call fclose

end:
    mov eax, 0
    mov rsp, rbp 
    pop rbp
    ret


input_error:
    mov rdi, error_input
    xor eax, eax
    call printf
    ; закрываем файл
    mov rdi, [file_d]
    call fclose

    jmp error_end

args_error:
    mov rdi, error_arguments
    mov rsi, [rsi]
    xor eax, eax
    call printf
    jmp error_end

open_error:
    mov rdi, open_failed
    mov rsi, [rsi]
    xor eax, eax
    call printf
    jmp error_end


error_end:
    mov rsp, rbp 
    pop rbp
    mov rdi, 1
    call exit


clear_buffer:
    push rbp
    mov rbp, rsp

.clear_loop:
    call getchar
    cmp eax, -1
    je input_error
    cmp eax, 10
    je .end_clear
    jmp .clear_loop

.end_clear:
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

