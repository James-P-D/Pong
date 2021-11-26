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
STD_OUTPUT_HANDLE           equ -11                                 ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
        
test_message                db "Hello world!", 13, 10               ; Our input/output byte
TEST_MESSAGE_LEN            equ $ - offset test_message             ; Length of message

NUMBER_BUFFER_SIZE          equ 10                                  ; TODO: How big? How many digits?
number_buffer               db NUMBER_BUFFER_SIZE dup(0)

cursor_info                 CONSOLE_CURSOR_INFO <20, 0>
console_buffer_info         CONSOLE_SCREEN_BUFFER_INFO <>

SPACE                       db 32
SPACE_LEN                   equ $ - offset SPACE
BLOCK                       db 219                                  ; Block char
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

player_1_score              dw 0
player_2_score              dw 0

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
console_out_handle          dd ?                                    ; Our ouput handle (currently undefined)
bytes_written               dd ?                                    ; Number of bytes written to output (currently undefined)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; .code section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code
start:                      call get_output_handle                  ; Get the input/output handles
                            call hide_cursor                        ; Hide the cursor
                            call get_console_settings               ; Get the console width and height
                            call clear_screen                       ; Clear the screen
                            
                            call GetTickCount                            
                            mov dword ptr [last_clock_ticks], eax
                                                        
                            mov ax, COLS_NEW                        ; Get the number of columns..
                            dec ax                                  ; ..decrease by 1..
                            mov word ptr [player_2_x], ax           ; ..and set the second player x position
                            
                            mov ax, ROWS_NEW                        ; Get the number of rows..
                            shr ax, 1                               ; ..bit-shift-right halves the value..
                            mov word ptr [player_1_y], ax           ; ..and use the mid-point to set player 1 y position..
                            mov word ptr [player_2_y], ax           ; ..and the same for player 2..
                            mov word ptr [ball_y], ax               ; ..and for the ball
                            
                            mov ax, COLS_NEW                        ; Get the number of columns again..
                            shr ax, 1                               ; ..halve it so we are mid-screen..
                            mov word ptr [ball_x], ax               ; ..and use it to set the ball x position
                            
                            
                            
                            
                            call draw_player_1
                            call draw_player_2
                            call write_player_1_score
                            call write_player_2_score
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
                            call clear_ball
                            
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
                            
read_key_cont0:             push PLAYER_1_UP_KEY
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

player_1_lost:              inc word ptr [player_2_score]
                            call write_player_2_score
                            jmp player_lost

player_2_lost:              inc word ptr [player_1_score]
                            call write_player_1_score
                            
player_lost:                call clear_ball
                            
                            mov ax, ROWS_NEW                        ; Get the number of rows..
                            shr ax, 1                               ; ..bit-shift-right halves the value..
                            mov word ptr [ball_y], ax               ; ..and use it to set the ball y position
                            
                            mov ax, COLS_NEW                        ; Get the number of columns again..
                            shr ax, 1                               ; ..halve it so we are mid-screen..
                            mov word ptr [ball_x], ax               ; ..and use it to set the ball x position
                           
                            call draw_ball
                            
                            jmp game_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; end_program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end_program:                call clear_screen
                            call show_cursor
                            push 0                          ; Exit code zero for success
                            call ExitProcess                ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
; write_player_1_score()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_player_1_score:       mov ax, word ptr [ROWS_NEW]
                            dec ax
                            mov bx, word ptr [COLS_NEW]
                            shr bx, 2
                            call set_cursor_position
                            
                            push word ptr [player_1_score]
                            call output_unsigned_byte
                            
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; write_player_2_score()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_player_2_score:       mov ax, word ptr [COLS_NEW]
                            shr ax, 2
                            mov bx, 3
                            mul bx
                            mov bx, ax
                            
                            mov ax, word ptr [ROWS_NEW]
                            dec ax
                            
                            call set_cursor_position
                            
                            push word ptr [player_2_score]
                            call output_unsigned_byte
                            
                            ret

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
; clear_ball()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_ball:                 mov eax, 0
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_unsigned_byte(BYTE: number)
; Destroys: EBP, 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_unsigned_byte:       pop ebp                         ; Pop the return address
                            pop ax                          ; Pop integer to output into AX
                            push ebp                        ; Push EBP back onto stack

                            and ax, 00FFh                   ; Make sure AX is in range 0..255                    
                            mov ecx, 0                      ; Set digits counter to zero     
                    
output_unsigned_byte_perform_calculation:                    
                            mov dx, 0
                            mov bx, 10                      ; Divide by 10
                            div bx                          ; Divide AX by BX                    
                                                            ; DL contains remainer, AL contains quotient
                            and edx, 000000FFh              ; Make sure EDX (remainer) is in range 0..255
                            add dl, 030h                    ; Add 30h (the letter '0' (zero)) so we map numbers to letters
                            push dx                         ; Push our letter to the stack
                            inc ecx                         ; Increment digit counter

                            cmp al, 0                       ; Check if quotient is zero
                            jne output_unsigned_byte_perform_calculation    ; If quotient is not zero, then we need to perform the operation again

                            mov edi, 0                      ; Set EDI to zero. This will point to 'number_buffer' starting at index 0
output_unsigned_byte_finished_calculation:
                            pop dx                          ; Read the last remainder from the stack
 
                            mov byte ptr [number_buffer + edi], dl ; Copy the letter to 'number_buffer'
                    
                            inc edi                         ; Incrememnt out pointer to 'number_buffer'
                            loop output_unsigned_byte_finished_calculation  ; Continue looping until ECX is zero

                            push edi                        ; At the end of the process, EDI will conveniently hold the number of characters written to 'number_buffer'. Pass it as a parameter to 'output_string'
                            push offset number_buffer
                            call output_string      
  
                            ret                             ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; clear_screen()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;al = y bl = x
clear_screen:               mov eax, 0
                            mov ebx, 0
                            
clear_screen_col_loop:      push eax
                            push ebx
                            call set_cursor_position
                            pop ebx
                            pop eax

                            push eax
                            push ebx
                            push SPACE_LEN
                            push offset SPACE
                            call output_string 
                            pop ebx
                            pop eax
                            
                            inc ebx
                            cmp bx, word ptr [COLS_NEW]
                            jne clear_screen_col_loop
                            
                            mov ebx, 0
                            inc eax
                            cmp ax, word ptr[ROWS_NEW]
                            jne clear_screen_col_loop
                            
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get_output_handle()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_output_handle:          push STD_OUTPUT_HANDLE          ; _In_ DWORD nStdHandle
                            call GetStdHandle               ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                            mov [console_out_handle], eax   ; Save the output handle
                            ret
                    
end start