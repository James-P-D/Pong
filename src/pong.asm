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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; .data section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.data
STD_OUTPUT_HANDLE           equ -11                             ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
        
test_message                db "Hello world!", 13, 10           ; Our input/output byte
TEST_MESSAGE_LEN            equ $ - offset test_message         ; Length of message

cursor_info                 CONSOLE_CURSOR_INFO <20, 0>
console_buffer_info         CONSOLE_SCREEN_BUFFER_INFO <>

SPACE                       db 32
SPACE_LEN                   equ $ - offset SPACE
BLOCK                       db 219                              ; Block char
BLOCK_LEN                   equ $ - offset BLOCK
BALL                        db 'O'
BALL_LEN                    equ $ - offset BALL

COLS_NEW                    dw 0
ROWS_NEW                    dw 0

PLAYER_1_UP_KEY             equ 'Q'
PLAYER_1_DOWN_KEY           equ 'A'
PLAYER_2_UP_KEY             equ 'P'
PLAYER_2_DOWN_KEY           equ 'L'
ESCAPE                      equ 27

player_1_y                  dw 0
player_1_x                  dw 0
player_2_y                  dw 0
player_2_x                  dw 0
PADDLE_SIZE                 equ 5

BALL_DIR_SE                 equ 0                                   ; South east movement
BALL_DIR_SW                 equ 1                                   ; South west movement
BALL_DIR_NW                 equ 2                                   ; North west movement
BALL_DIR_NE                 equ 3                                   ; North east movement
ball_dir                    db BALL_DIR_SE
ball_x                      dw 0
ball_y                      dw 0

last_clock_ticks            dw 0
TICK_INTERVAL               dd 10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; .data? section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.data?
console_out_handle          dd ?                                ; Our ouput handle (currently undefined)
bytes_written               dd ?                                ; Number of bytes written to output (currently undefined)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; .code section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code
start:                      call get_output_handle              ; Get the input/output handles
                            call hide_cursor
                            call get_console_settings
                            
                            call GetTickCount                            
                            mov dword ptr [last_clock_ticks], eax
                            
                            mov ax, 0
                            mov bx, 0
                            call set_cursor_position
                            
                            mov ax, COLS_NEW
                            dec ax
                            mov word ptr [player_2_x], ax
                            
                            mov ax, ROWS_NEW
                            shr ax, 1
                            mov word ptr [player_1_y], ax
                            mov word ptr [player_2_y], ax
                            mov word ptr [ball_y], ax
                            
                            mov ax, COLS_NEW
                            shr ax, 1
                            mov word ptr [ball_x], ax
                            
                            
                            
                            
                            call draw_player_1
                            call draw_player_2
                            call draw_ball
                            

game_loop:                  push 20
                            call Sleep
                            
                            ;call GetTickCount
                            ;
                            ;mov ebx, dword ptr [last_clock_ticks]
                            ;add ebx, TICK_INTERVAL
                            ;  
                            ;cmp eax, ebx
                            ;jge read_key
                            ;
                            ;mov dword ptr [last_clock_ticks], eax
                                                       
                            
                            ; Overwrite the current ball with a space
                            mov eax, 0
                            mov ebx, 0
                            mov al, byte ptr [ball_y]
                            mov bl, byte ptr [ball_x]
                            
                            push eax
                            push ebx
                            call set_cursor_position
                            pop ebx
                            pop eax

                            push SPACE_LEN
                            push offset SPACE
                            call output_string
                            
                            ; calculate new ball position
                            
                            ;cmp byte ptr [ball_dir], BALL_DIR_SE
                            ;jne check_ball_dir_sw
                            
                            ;inc byte ptr [ball_x]
                            ;inc byte ptr [ball_y]
                            ;jmp ??????
                            
check_ball_dir_sw:                            
                            
check_ball:                            
                            ; check if wall
                            ; check if batt
                        
                            call draw_ball
                            
                            
                            
read_key:                   push ESCAPE
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


                            jmp game_loop

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

player_1_down_pressed:      mov ax, word ptr [player_1_y]
                            mov bx, ROWS_NEW
                            sub bx, PADDLE_SIZE
                            dec bx                            
                            cmp ax, bx
                            je player_1_down_pressed_done
                            
                            inc ax
                            mov word ptr [player_1_y], ax
                            
                            mov eax, 0
                            mov ax, word ptr [player_1_y]
                            dec ax
                            mov ebx, 0
                            mov bx, word ptr [player_1_x]
                            call set_cursor_position
                            
                            push SPACE_LEN
                            push offset SPACE
                            call output_string
                            
                            call draw_player_1
                            
player_1_down_pressed_done: ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_2_up_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_2_up_pressed:        mov ax, word ptr [player_2_y]
                            cmp ax, 0
                            je player_2_up_pressed_done

                            dec ax                            
                            mov word ptr [player_2_y], ax
                            
                            mov eax, 0
                            mov ax, word ptr [player_2_y]
                            add eax, PADDLE_SIZE
                            mov ebx, 0
                            mov bx, word ptr [player_2_x]
                            call set_cursor_position
                            
                            push SPACE_LEN
                            push offset SPACE
                            call output_string
                            
                            call draw_player_2

player_2_up_pressed_done:   ret
                            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_2_down_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_2_down_pressed:      mov ax, word ptr [player_2_y]
                            mov bx, ROWS_NEW
                            sub bx, PADDLE_SIZE
                            dec bx
                            cmp ax, bx
                            je player_2_down_pressed_done
                            
                            inc ax
                            mov word ptr [player_2_y], ax
                            
                            mov eax, 0
                            mov ax, word ptr [player_2_y]
                            dec ax
                            mov ebx, 0
                            mov bx, word ptr [player_2_x]
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
                            call show_cursor
                            push 0                          ; Exit code zero for success
                            call ExitProcess                ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw_player_1()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_player_1:              mov eax, 0
                            mov ebx, 0
                            mov ax, word ptr [player_1_y]
                            mov bx, word ptr [player_1_x]
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
                            mov ax, word ptr [player_2_y]
                            mov bx, word ptr [player_2_x]
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
; draw_ball()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_ball:                  mov eax, 0
                            mov ebx, 0
                            mov ax, word ptr [ball_y]
                            mov bx, word ptr [ball_x]
                            
                            push eax
                            push ebx
                            call set_cursor_position
                            pop ebx
                            pop eax

                            push BALL_LEN
                            push offset BALL
                            call output_string
                            
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get_console_settings()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_console_settings:       lea eax, [console_buffer_info]
                            push eax
                            push console_out_handle                            
                            call GetConsoleScreenBufferInfo
                            
                            mov ax, word ptr [console_buffer_info.srWindow.Right]
                            mov bx, word ptr [console_buffer_info.srWindow.Left]
                            sub ax, bx
                            inc ax
                            mov word ptr [COLS_NEW], ax 
                            
                            mov ax, word ptr [console_buffer_info.srWindow.Bottom]
                            mov bx, word ptr [console_buffer_info.srWindow.Top]
                            sub ax, bx
                            inc ax
                            mov word ptr [ROWS_NEW], ax 
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hide_cursor()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_cursor:                mov dword ptr [cursor_info.dwSize], 20
                            mov dword ptr [cursor_info.bVisible], 0
                            lea eax, [cursor_info]
                            push eax
                            push console_out_handle
                            call SetConsoleCursorInfo
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; show_cursor()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_cursor:                mov dword ptr [cursor_info.dwSize], 20
                            mov dword ptr [cursor_info.bVisible], 1
                            lea eax, [cursor_info]
                            push eax
                            push console_out_handle
                            call SetConsoleCursorInfo
                            ret
                            
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