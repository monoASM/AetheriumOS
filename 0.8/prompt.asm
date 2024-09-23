org 0x7c00
bits 16

jmp start                     ; сразу переходим в start

%include "strings.asm"
%include "compare.asm"

; ====================================================

start:
    cli                                ; запрещаем прерывания, чтобы наш код 
                                       ; ничто лишнее не останавливало

    mov ah, 0x00              ; очистка экрана
    mov al, 0x03
    int 0x10

    mov sp, 0x7c00            ; инициализация стека

    mov si, greetings         ; печатаем приветственное сообщение
    call print_string_si      ; после чего сразу переходим в mainloop

mainloop:
    mov si, prompt            ; печатаем стрелочку
    call print_string_si

    call get_input            ; вызываем функцию ожидания ввода

    jmp mainloop              ; повторяем mainloop...

get_input:
    mov bx, 0                 ; инициализируем bx как индекс для хранения ввода

input_processing:
    mov ah, 0x0               ; параметр для вызова 0x16
    int 0x16                  ; получаем ASCII код

    cmp al, 0x0d              ; если нажали enter
    je check_the_input        ; то вызываем функцию, в которой проверяем, какое
                              ; слово было введено

    cmp al, 0x8               ; если нажали backspace
    je backspace_pressed

    cmp al, 0x3               ; если нажали ctrl+c
    je stop_cpu

    mov ah, 0x0e              ; во всех противных случаях - просто печатаем
                              ; очередной символ из ввода
    int 0x10

    mov [input+bx], al        ; и сохраняем его в буффер ввода
    inc bx                    ; увеличиваем индекс

    cmp bx, 64                ; если input переполнен
    je check_the_input        ; то ведем себя так, будто был нажат enter

    jmp input_processing      ; и идем заново

stop_cpu:
    mov si, bye           ; печатаем прощание
    call print_string_si

    ; Ожидаем завершения работы системы
    mov ax, 0x5307
    int 0x21

    ; Выключаем компьютер
    mov eax, 0x2000
    int 0x15

backspace_pressed:
    cmp bx, 0                 ; если backspace нажат, но input пуст, то
    je input_processing       ; ничего не делаем

    mov ah, 0x0e              ; печатаем backspace. это значит, что каретка
    int 0x10                  ; просто передвинется назад, но сам символ не сотрется

    mov al, ' '               ; поэтому печатаем пробел на том месте, куда
    int 0x10                  ; встала каретка

    mov al, 0x8               ; пробел передвинет каретку в изначальное положение
    int 0x10                  ; поэтому еще раз печатаем backspace

    dec bx
    mov byte [input+bx], 0    ; и убираем из input последний символ

    jmp input_processing      ; и возвращаемся обратно

check_the_input:
    inc bx
    mov byte [input+bx], 0    ; в конце ввода ставим ноль, означающий конец
                              ; стркоки (тот же '\0' в Си)

    mov si, new_line          ; печатаем символ новой строки
    call print_string_si

    mov si, help_command      ; в si загружаем заранее подготовленное слово help
    mov bx, input             ; а в bx - сам ввод
    call compare_strs_si_bx   ; сравниваем si и bx (введено ли help)

    cmp cx, 1                 ; compare_strs_si_bx загружает в cx 1, если
                              ; строки равны друг другу
    je equal_help             ; равны => вызываем функцию отображения
                              ; текста help


    ; Info
    mov si, inf_com
    mov bx, input
    call compare_strs_si_bx

    cmp cx, 1

    je equal_inf
    

    ; Commands
    mov si, comm_command
    mov bx, input
    call compare_strs_si_bx

    cmp cx, 1

    je equal_comm
    
    ; clear screen
    mov si, cls_com
    mov bx, input
    call compare_strs_si_bx

    cmp cx, 1

    je equal_cls

    ; Wrong
    jmp equal_to_nothing      ; если не равны, то выводим "Wrong command!"

equal_inf:
    mov si, inf_desk
    call print_string_si

    jmp done

equal_cls:
    mov ah, 0x00              ; очистка экрана
    mov al, 0x03
    int 0x10

    jmp done

equal_help:
    mov si, help_desc
    call print_string_si

    jmp done
    
equal_comm:
    mov si, comm_desk
    call print_string_si

    jmp done

equal_to_nothing:
    mov si, wrong_command
    call print_string_si

    jmp done

; done очищает всю переменную input
done:
    cmp bx, 0                 ; если зашли дальше начала input в памяти
    je exit                   ; то вызываем функцию, идующую обратно в mainloop

    dec bx                    ; если нет, то инициализируем очередной байт нулем
    mov byte [input+bx], 0

    jmp done                  ; и делаем то же самое заново

exit:
    ret

; 0x0d - символ возварата картки, 0xa - символ новой строки
wrong_command: db "Invalid Command", 0x0d, 0xa, 0
greetings: db "Welcome To AetheriumOS version 0.8, Release!", 0x0d, 0xa, 0xa, 0

help_desc: db "Commands: com", 0x0d, 0xa, 0
help_command: db "hlp", 0

prompt: db "$>", 0
new_line: db 0x0d, 0xa, 0

comm_desk: db "Commands: inf, com, hlp", 0x0d, 0xa, 0
comm_command: db "com", 0

inf_desk: db "AetheriumOS version 0.8. Releases in Telegram: @noname_hyperuser", 0x0d, 0xa, 0
inf_com: db "inf", 0

cls_com: db "cls", 0

bye: db 0x0d, 0xa, "The power can be turned off!", 0x0d, 0xa, 0
input: times 64 db 0          ; размер буффера - 64 байта

;здесь будут еще команды

times 1022 - ($-$$) db 0
dw 0xaa55