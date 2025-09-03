bits	64
; Выполнить сортировку столбцов матрицы по значению суммы элементов в них.
; Пирамидальная сортировка (Heap sort).
section .data
n: 
	db 3 ; К-во строк
m:
	db 4 ; К-во столбцов
align 8
matrix:
	dq 11, 23, 41, 79
	dq 10, 22, 53, 45
	dq 27, 85, 44, 11
section .bss
sums:
	resq 4
section .text
global _start
_start:
	; Находим суммы в каждом столбце и заносим в sums
	movzx r9, byte[m]
	movzx r10, byte[n]
	mov rcx, r9 ; Передали количество столбцов в регистр счетчика циклов rcx
	cmp rcx, 1
	jle end ; Если в матрице 1 столбец - конец
	mov rbx, matrix ; Установили указатель на начало матрицы
sum:
	xor rdi, rdi ; обнулили указатель строки
	mov rax, [rbx]
	push rcx ; Сохранили количество оставшися столбцов в цикле
	mov rcx, r10 ; записали в счетчик цикла количество строк для суммирования
	dec rcx
	jrcxz sum_write ; Если 1 строка в матрице - не заходим во внутренний цикл
sum_inner:
	add rdi, r9
	add rax, [rbx+rdi*8] ; добавляем очередное значение в столбце к сумме
	jo overflow
	loop sum_inner ; Повторяем для всего столбца
sum_write:
	add rdi, r9 ; Находим адрес, куда записать сумму
	mov [rbx+rdi*8], rax
	add rbx, 8 ; Передвигаем указатель первого элемента в столбце
	pop rcx
	loop sum
end:
	mov eax, 60
	mov edi, 0
	syscall
overflow:
	mov rax, 60
	mov rdi, 2
	syscall
