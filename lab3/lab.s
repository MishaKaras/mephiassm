bits	64
;	Продублировать в строке все слова чётной длины.
;	Ввод данных — стандартный поток ввода
;	Вывод данных — файл

; Номера системных вызовов (в eax)
SYS_READ equ 0	; syscall номер 0 — чтение
SYS_WRITE equ 1	; syscall номер 1 — запись
SYS_OPEN equ 2	; syscall номер 2 — открытие файла
SYS_CLOSE equ 3	; syscall номер 2 — закрытие файла
SYS_EXIT equ 60	; syscall номер 60 — exit

; Дескрипторы (в rdi)
STDIN equ 0
STDOUT equ 1
STDERR equ 2

; Флаги открытия файла
O_WRONLY equ 1		; только на запись
O_CREATE equ 64		; создать файл при отсутствии
O_APPEND equ 1024	; добавлять в конец файла
O_TRUNK  equ 512	; очищать при открытии
FILE_FLAGS equ (O_WRONLY | O_CREATE | O_APPEND | O_TRUNK)

; Права доступа
FILE_ACCESS equ 0o644	; Владелец - чтение+запись, остальные - чтение


; Получение имени файла через среду окружения
section	.data
err1:
	db	"Usage: "
err1len	equ	$-err1
err2:
	db	" name_of_variable", 10
err2len	equ	$-err2
err3:
	db	"Not found"
nl:
	db	10
err3len	equ	$-err3
open_err:
	db "Cannot open file", 10
open_err_len equ $-open_err

section .bss
	file_d resq 1
	file_path resq 1
	file_path_ln resq 1


section .text
global _start
_start:
	cmp dword[rsp], 2
	je find_prompt
	; Если > 2 параметров, то ошибка
	mov	eax, SYS_WRITE
	mov	edi, STDERR
	mov	rsi, err1
	mov	edx, err1len
	syscall
	mov	eax, 1
	mov	rsi, [rsp+8]
	xor	edx, edx
prog_name:
	cmp	byte[rsi+rdx], 0
	je	err2_print
	inc	rdx
	jmp	prog_name
err2_print:
	syscall
	mov	eax, SYS_WRITE
	mov	rsi, err2
	mov	edx, err2len
	syscall
	jmp error
find_prompt:
	mov rdi, [rsp+16] ; указывает на FILENAME (аргумент командной строки)
	mov	ebx, 3 ; NULL после аргументов командной строки
find_fname:
	inc ebx ; начало параметров среды
	mov	rsi, [rsp+rbx*8] ; указывает на переменную среды (FILENAME=...)
	or rsi, rsi
	je not_found
	xor ecx, ecx
check_name:
	mov al, [rdi+rcx]
	cmp al, [rsi+rcx]
	jne check_prompt
	inc rcx
	jmp check_name
check_prompt:
	or al, al
	jnz find_fname
	cmp byte[rsi+rcx], '='
	jne find_fname
get_name:
	inc rcx
	add rsi, rcx ; теперь в rsi - начала пути к файлу
	xor rdi, rdi ; конец строки пути
find_end:
	cmp byte[rsi+rdi], 0
	je save_path
	inc rdi
	jmp find_end

save_path:
	mov [file_path], rsi ; адрес
	mov [file_path_ln], rdi ; длина адреса
open_file:
	mov eax, SYS_OPEN
	mov rbx, rdi	; длина строки-пути в rbx
	mov rdi, rsi	; адрес буфера с именем файла
	xor rsi, rsi
	mov rsi, FILE_FLAGS
	mov rdx, FILE_ACCESS
	syscall
	test rax, rax
	js open_error
	mov [file_d], rax ; сохранили fd
	jmp start_dialog

not_found:
	mov	eax, SYS_WRITE
	mov	edi, STDERR
	mov	rsi, err3
	mov	edx, err3len
	syscall
	jmp error

open_error:
	mov eax, SYS_WRITE
	mov edi, STDERR
	mov rsi, open_err
	mov rdx, open_err_len
	syscall
	jmp error


section .data
	start_msg:
	db "Input string: ", 0
	startlen equ $-start_msg
	size equ 1024

	write_err:
	db "Write failed", 10
	write_err_len equ $-write_err

	ov_err:
    db "Input line too long", 10
	ov_err_len equ $ - ov_err

section .bss
	string resb size
	res_string resb size*2

section .text
start_dialog:
	; Выводим стартовое сообщение
	mov eax, SYS_WRITE
	mov edi, STDOUT
	mov rsi, start_msg
	mov edx, startlen
	syscall
read_str:
	; Считываем строку из консоли
	mov eax, SYS_READ
	mov edi, STDIN
	mov rsi, string
	mov edx, size
	syscall
	; Проверка ввода на ошибку или eof
	test eax, eax
	js error
	jz eof	
	; проверка на длину строки
	cmp byte [string+rax-1], 10
	jne overflow
	xor ecx, ecx
parse:
	xor rdi, rdi	; Указатель позиции в результирующей строке
	xor rsi, rsi	; Указатель позиции в исходной строке
filter:
	; Пропускаем разделители
	mov al, byte [string + rsi]
	cmp al, 10
	je entr
	cmp al, ' '
	je sep
	cmp al, 9
	je sep
	jmp word_start
sep:
	inc rsi
	jmp filter
word_start:
	; Запомнили индекс начала слова
	mov rcx, rsi
scan_word:
	mov al, byte[string + rsi]
	cmp al, 10
	je end_word
	cmp al, ' '
	je end_word
	cmp al, 9
	je end_word
	inc rsi
	jmp scan_word
end_word:
	; Нашли конец слова
	mov r15, rsi
	sub r15, rcx
	test r15, 1
	jnz odd		; нечетное - пишем 1 раз
	call copy_word
odd:	
	call copy_word
	jmp filter
entr:
	cmp rdi, 0
	je place_entr
	dec rdi
place_entr:
	mov byte[res_string+rdi], 10
	inc rdi

write_in_file:
	mov rbx, rdi
	mov eax, SYS_WRITE
	mov edi, [file_d]		; Дескриптор файла для записи
	mov rsi, res_string		; результат (строка)
	mov rdx, rbx			; длина строки
	syscall
	test rax, rax
	js write_error
	jmp start_dialog

write_error:
	mov eax, SYS_WRITE
	mov edi, STDERR
	mov rsi, write_err
	mov rdx, write_err_len
	syscall
	call close_file
	jmp error

overflow:
	call clean_stdin
	mov eax, SYS_WRITE
	mov edi, STDERR
	mov rsi, ov_err
	mov rdx, ov_err_len
	syscall
	call close_file
	jmp error

error:
	mov edi, 1
	jmp _end
eof:
	call close_file
	xor edi, edi
	jmp _end

_end: 
	mov eax, SYS_EXIT
	syscall


copy_word:
	push rcx
.loop:
	cmp rcx, rsi
	je .end_copy
	mov al, byte [string + rcx]
	mov byte [res_string + rdi], al
	inc rdi 
	inc rcx
	jmp .loop
.end_copy:
	pop rcx
	; вставляем пробел
	mov byte[res_string+rdi], ' '
	inc rdi
	ret

; При завершении из-за overflow очищаем буфер ввода
clean_stdin:
	mov eax, SYS_READ
	mov edi, STDIN
	mov rsi, string
	mov edx, 1
	syscall
	test eax, eax
	jle .clean_done
	cmp byte[string], 10
	jne clean_stdin
.clean_done:
	ret

close_file:
	; закрываем файл
	mov eax, SYS_CLOSE
	mov edi, [file_d]
	syscall
	ret