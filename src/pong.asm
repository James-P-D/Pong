.386                  ; 386 Processor Instruction Set
.model flat, stdcall  ; Flat memory model and stdcall method
option casemap: none  ; Case Sensitive

include c:\\masm32\\include\\windows.inc
include c:\\masm32\\include\\kernel32.inc
include c:\\masm32\\include\\masm32.inc
include c:\\masm32\\include\\user32.inc

includelib c:\\masm32\\lib\\kernel32.lib 
includelib c:\\masm32\\lib\\user32.lib 
includelib c:\\masm32\\m32lib\\masm32.lib

.data
STD_OUTPUT_HANDLE           equ -11                             ; https://docs.microsoft.com/en-us/windows/console/getstdhandle

        
test_message                db "Hello world!", 13, 10           ; Our input/output byte
TEST_MESSAGE_LEN            equ $ - offset test_message         ; Length of message
SPACE                       db 32
SPACE_LEN                   equ $ - offset SPACE
BLOCK                       db 219                              ; Block char
BLOCK_LEN                   equ $ - offset BLOCK

COLS                        equ 80
ROWS                        equ 29

PLAYER_1_UP_KEY             equ 'Q'
PLAYER_1_DOWN_KEY           equ 'A'
PLAYER_2_UP_KEY             equ 'P'
PLAYER_2_DOWN_KEY           equ 'L'
ESCAPE                      equ 27

player_1_y                  db (ROWS / 2) - (PADDLE_SIZE / 2)
player_1_x                  equ 1
player_2_y                  db (ROWS / 2) - (PADDLE_SIZE / 2)
player_2_x                  equ COLS - 2
PADDLE_SIZE                 equ 5

.data?
console_out_handle          dd ?                                ; Our ouput handle (currently undefined)
bytes_written               dd ?                                ; Number of bytes written to output (currently undefined)

.code
start:                      call get_output_handle              ; Get the input/output handles
                            ;call hide_cursor
                            
                            mov ax, 0
                            mov bx, 0
                            call set_cursor_position
                            
                            call draw_player_1
                            call draw_player_2
                            

read_key:                   push 50
                            call Sleep
                            
                            push ESCAPE
                            call GetAsyncKeyState
                            cmp ax, 0
                            jne end_program
                            
                            push PLAYER_1_UP_KEY
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont1
                            call player_1_up_pressed
                            
read_key_cont1:             push PLAYER_1_DOWN_KEY
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont2
                            call player_1_down_pressed
                            
read_key_cont2:             push PLAYER_2_UP_KEY
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont3
                            call player_2_up_pressed
                            
read_key_cont3:             push PLAYER_2_DOWN_KEY
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont4
                            call player_2_down_pressed
                            
read_key_cont4:


                            jmp read_key

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_1_up_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_1_up_pressed:        mov al, byte ptr [player_1_y]
                            cmp al, 0
                            je player_1_up_pressed_done

                            dec al                            
                            mov byte ptr [player_1_y], al
                            
                            mov eax, 0
                            mov al, byte ptr [player_1_y]
                            add eax, PADDLE_SIZE
                            mov ebx, 0
                            mov bl, byte ptr [player_1_x]
                            call set_cursor_position
                            
                            push SPACE_LEN
                            push offset SPACE
                            call output_string
                            
                            call draw_player_1

player_1_up_pressed_done:   ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_1_down_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_1_down_pressed:      mov al, byte ptr [player_1_y]
                            cmp al, ROWS - PADDLE_SIZE
                            je player_1_down_pressed_done
                            
                            inc al
                            mov byte ptr [player_1_y], al
                            
                            mov eax, 0
                            mov al, byte ptr [player_1_y]
                            dec al
                            mov ebx, 0
                            mov bl, byte ptr [player_1_x]
                            call set_cursor_position
                            
                            push SPACE_LEN
                            push offset SPACE
                            call output_string
                            
                            call draw_player_1
                            
player_1_down_pressed_done: ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_2_up_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_2_up_pressed:        mov al, byte ptr [player_2_y]
                            cmp al, 0
                            je player_2_up_pressed_done

                            dec al                            
                            mov byte ptr [player_2_y], al
                            
                            mov eax, 0
                            mov al, byte ptr [player_2_y]
                            add eax, PADDLE_SIZE
                            mov ebx, 0
                            mov bl, byte ptr [player_2_x]
                            call set_cursor_position
                            
                            push SPACE_LEN
                            push offset SPACE
                            call output_string
                            
                            call draw_player_2

player_2_up_pressed_done:   ret
                            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_2_down_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_2_down_pressed:      mov al, byte ptr [player_2_y]
                            cmp al, ROWS - PADDLE_SIZE
                            je player_2_down_pressed_done
                            
                            inc al
                            mov byte ptr [player_2_y], al
                            
                            mov eax, 0
                            mov al, byte ptr [player_2_y]
                            dec al
                            mov ebx, 0
                            mov bl, byte ptr [player_2_x]
                            call set_cursor_position
                            
                            push SPACE_LEN
                            push offset SPACE
                            call output_string
                            
                            call draw_player_2
                            
player_2_down_pressed_done: ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; end_program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


end_program:                
                            ;call show_cursor
                            push 0                          ; Exit code zero for success
                            call ExitProcess                ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw_player_1()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_player_1:              mov eax, 0
                            mov ebx, 0
                            mov al, byte ptr [player_1_y]
                            mov bl, byte ptr [player_1_x]
                            mov ecx, PADDLE_SIZE
                            
draw_player_1_write_char:   push eax
                            push ebx
                            push ecx
                            call set_cursor_position
                            
                            push BLOCK_LEN
                            push offset BLOCK
                            call output_string

                            pop ecx
                            pop ebx
                            pop eax
                            
                            inc eax
                            loop draw_player_1_write_char

                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw_player_2()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_player_2:              mov eax, 0
                            mov ebx, 0
                            mov al, byte ptr [player_2_y]
                            mov bl, byte ptr [player_2_x]
                            mov ecx, PADDLE_SIZE
                            
draw_player_2_write_char:   push eax
                            push ebx
                            push ecx
                            call set_cursor_position
                            
                            push BLOCK_LEN
                            push offset BLOCK
                            call output_string

                            pop ecx
                            pop ebx
                            pop eax
                            
                            inc eax
                            loop draw_player_2_write_char

                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hide_cursor()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;hide_cursor:                mov dword ptr [CONSOLE_CURSOR_INFO.dwSize], 50
;                            mov dword ptr [CONSOLE_CURSOR_INFO.bVisible], 0
;                            lea eax, [CONSOLE_CURSOR_INFO_size]
;                            push eax
;                            push console_out_handle
;                            call SetConsoleCursorInfo
;                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; show_cursor()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;show_cursor:                ;mov byte ptr [CONSOLE_CURSOR_INFO_visible], 0
;                            lea eax, [CONSOLE_CURSOR_INFO_size]
;                            push eax
;                            push console_out_handle
;                            call SetConsoleCursorInfo
;                            ret
                            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set_cursor_position(ax = y, bx = x)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_position:        shl eax, 16
                            mov ax, bx
                            push eax
                            push console_out_handle
                            call SetConsoleCursorPosition
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_string()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_string:              pop ebp                         ; Pop the return address
                            pop esi                         ; Pop length-of-string into edi
                            pop edi                         ; Pop offset-of-string into esi
                            
                            push 0                          ; _Reserved_      LPVOID  lpReserved
                            push offset bytes_written       ; _Out_           LPDWORD lpNumberOfCharsWritten
                            push edi                        ; _In_            DWORD   nNumberOfCharsToWrite
                            push esi                        ; _In_      const VOID *  lpBuffer
                            push console_out_handle         ; _In_            HANDLE  hConsoleOutput
                            call WriteConsole               ; https://docs.microsoft.com/en-us/windows/console/writeconsole

                            push ebp                        ; Restore return address
                            ret                             ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get_output_handle()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_output_handle:          push STD_OUTPUT_HANDLE          ; _In_ DWORD nStdHandle
                            call GetStdHandle               ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                            mov [console_out_handle], eax   ; Save the output handle
                            ret
                    
end start