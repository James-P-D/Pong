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

NUMBER_BUFFER_SIZE          equ 10                                  ; Buffer for outputting score
number_buffer               db NUMBER_BUFFER_SIZE dup(0)            

cursor_info                 CONSOLE_CURSOR_INFO <20, 0>             ; Struct for storing coursor info (hide/show)
console_buffer_info         CONSOLE_SCREEN_BUFFER_INFO <>           ; Struct for storing console size (width/height)

SPACE                       db 32                                   ; Space character for overwriting
SPACE_LEN                   equ $ - offset SPACE
BLOCK                       db 219                                  ; Block char
BLOCK_LEN                   equ $ - offset BLOCK
BALL                        db 'O'                                  ; Ball char
BALL_LEN                    equ $ - offset BALL

PLAYER_1_UP_KEY             equ 'Q'                                 ; Player 1 up key
PLAYER_1_DOWN_KEY           equ 'A'                                 ; Player 1 down key
PLAYER_2_UP_KEY             equ 'P'                                 ; Player 2 up key
PLAYER_2_DOWN_KEY           equ 'L'                                 ; Player 2 down key
ESCAPE                      equ 27                                  ; ESC to end game

cols                        dw 0                                    ; Cols in console
rows                        dw 0                                    ; Rows in console

player_1_score              dw 0                                    ; Player 1 score
player_2_score              dw 0                                    ; Player 2 score

player_1_y                  dw 0                                    ; Player positions
player_1_x                  dw 0
player_2_y                  dw 0
player_2_x                  dw 0
PADDLE_SIZE                 equ 5

BALL_DIR_SE                 equ 0                                   ; South east movement
BALL_DIR_SW                 equ 1                                   ; South west movement
BALL_DIR_NW                 equ 2                                   ; North west movement
BALL_DIR_NE                 equ 3                                   ; North east movement

ball_dir                    db BALL_DIR_SE                          ; Ball direction
ball_x                      dw 0                                    ; Ball position
ball_y                      dw 0

last_clock_ticks            dd 0                                    ; Ball movement tick interval
DEFAULT_INTERVAL            equ 100                                 
INTERVAL_STEP               equ 30                                  ; Interval increase to speed up ball as game progresses
tick_interval               dd DEFAULT_INTERVAL
GAME_LOOP_TICK              equ 20                                  ; Game loop sleep

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
                            
                            call GetTickCount                       ; Get the ticks..  
                            mov dword ptr [last_clock_ticks], eax   ; ..and store them to later
                                                        
                            mov ax, cols                            ; Get the number of columns..
                            dec ax                                  ; ..decrease by 1..
                            mov word ptr [player_2_x], ax           ; ..and set the second player x position
                            
                            mov ax, rows                            ; Get the number of rows..
                            shr ax, 1                               ; ..bit-shift-right halves the value..
                            mov word ptr [player_1_y], ax           ; ..and use the mid-point to set player 1 y position..
                            mov word ptr [player_2_y], ax           ; ..and the same for player 2..
                            mov word ptr [ball_y], ax               ; ..and for the ball
                            
                            mov ax, cols                            ; Get the number of columns again..
                            shr ax, 1                               ; ..halve it so we are mid-screen..
                            mov word ptr [ball_x], ax               ; ..and use it to set the ball x position
                            
                            call draw_player_1                      ; Draw the players
                            call draw_player_2
                            call write_player_1_score               ; Write the scores
                            call write_player_2_score
                            call draw_ball                          ; Draw the ball

game_loop:                  push GAME_LOOP_TICK                     ; Sleep for 20ms 
                            call Sleep
                            
                            call GetTickCount                       ; Get the tick count
                            
                            mov ebx, dword ptr [last_clock_ticks]
                            add ebx, tick_interval
                              
                            cmp eax, ebx
                            jle read_key                            ; If not passed the interval, don't animate ball, just go check keyboard for presses
                            
                            mov dword ptr [last_clock_ticks], eax
                            
                            call clear_ball                         ; Overwrite the current ball with a space

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            
; South East Check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            

check_ball_dir_se:          cmp byte ptr [ball_dir], BALL_DIR_SE    ; Check if moving sout-east
                            jne check_ball_dir_ne                   ; ..if not, go check for other directions
                            
                            inc word ptr [ball_x]                   ; Inc x and y since moving SE
                            inc word ptr [ball_y]                   
                            
                            mov ax, word ptr [rows]                 ; Get the rows
                            sub ax, 2                               ; Subtract 2 to get rid of bottom score lines
                            cmp ax, word ptr [ball_y]               ; Check if we hit the bottom
                            jne check_ball_dir_se_wall              ; If not, go check to see if we hit right-wall
                            
                            mov byte ptr [ball_dir], BALL_DIR_NE    ; Update to move north-eastward                         
                            
check_ball_dir_se_wall:     mov ax, word ptr [cols]                 ; Get the columns
                            dec ax                                  ; 
                            cmp ax, word ptr [ball_x]               ; See if hit the wall
                            jne check_ball_dir_se_paddle            ; ..if not, check if hit the paddle
                            
                            call draw_ball                          ; Draw the ball
                            push 1000                               ; Brief pause
                            call Sleep
                            
                            jmp player_2_lost                       ; Update scores and reset since player 2 just lost
                            
check_ball_dir_se_paddle:   dec ax                                  ; Decrement ax (which still contains [cols])
                            cmp ax, word ptr [ball_x]               ; See if at paddle
                            jne draw_new_ball                       ; ..if not, just draw the ball
                            
                            mov bx, word ptr [player_2_y]           ; ..otherwise, the player's y position
                            dec bx
                            mov cx, word ptr [ball_y]               ; ..and the ball's y position
                            cmp cx, bx                              ; Check if ball is above paddle..
                            jl draw_new_ball                        ; ..if it is, then just go ahead and draw the ball
                            
                            add bx, PADDLE_SIZE                     ; Add the paddle size so we check the bottom
                            cmp cx, bx                              ; Check if ball is below paddle..
                            jg draw_new_ball                        ; ..if it is, then just go ahead and draw the ball
                            
                            mov byte ptr [ball_dir], BALL_DIR_SW    ; ..otherwise, change the direction to south-west..
                            
                            add cx, 2                               ; ..BUT, we need to check we are not in a corner!
                            cmp cx, word ptr [rows]                 ; 
                            jne check_ball_dir_se_done              ; If we are not, then just continue..
                            
                            mov byte ptr [ball_dir], BALL_DIR_NW    ; ..otherwise update the direction to north-west
                            
check_ball_dir_se_done:     call update_tick_interval               ; Speed the ball up..
                            jmp draw_new_ball                       ; ..and draw it
                                                        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            
; North East Check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            

check_ball_dir_ne:          cmp byte ptr [ball_dir], BALL_DIR_NE
                            jne check_ball_dir_nw
                            
                            inc word ptr [ball_x]
                            dec word ptr [ball_y]
                            
                            mov ax, 0
                            cmp ax, word ptr [ball_y]
                            jne check_ball_dir_ne_wall
                            
                            mov byte ptr [ball_dir], BALL_DIR_SE
                            
check_ball_dir_ne_wall:     mov ax, word ptr [cols]
                            dec ax
                            cmp ax, word ptr [ball_x]
                            jne check_ball_dir_ne_paddle
                            
                            call draw_ball
                            push 1000
                            call Sleep
                            
                            jmp player_2_lost
                            
check_ball_dir_ne_paddle:   dec ax
                            cmp ax, word ptr [ball_x]
                            jne draw_new_ball
                            
                            mov bx, word ptr [player_2_y]
                            mov cx, word ptr [ball_y]
                            cmp cx, bx
                            jl draw_new_ball
                            
                            add bx, PADDLE_SIZE
                            cmp cx, bx
                            jg draw_new_ball
                            
                            mov byte ptr [ball_dir], BALL_DIR_NW
                            call update_tick_interval
                            jmp draw_new_ball
                            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            
; North West Check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            

check_ball_dir_nw:          cmp byte ptr [ball_dir], BALL_DIR_NW
                            jne check_ball_dir_sw
                            
                            dec word ptr [ball_x]
                            dec word ptr [ball_y]
                            
                            mov ax, 0
                            cmp ax, word ptr [ball_y]
                            jne check_ball_dir_nw_wall
                            
                            mov byte ptr [ball_dir], BALL_DIR_SW
                            
check_ball_dir_nw_wall:     mov ax, 0
                            cmp ax, word ptr [ball_x]
                            jne check_ball_dir_nw_paddle
                            
                            call draw_ball
                            push 1000
                            call Sleep
                            
                            jmp player_1_lost

check_ball_dir_nw_paddle:   inc ax
                            cmp ax, word ptr [ball_x]
                            jne draw_new_ball
                            
                            mov bx, word ptr [player_1_y]
                            mov cx, word ptr [ball_y]
                            cmp cx, bx
                            jl draw_new_ball
                            
                            add bx, PADDLE_SIZE
                            cmp cx, bx
                            jg draw_new_ball
                            
                            mov byte ptr [ball_dir], BALL_DIR_NE
                            call update_tick_interval
                            jmp draw_new_ball

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            
; South West Check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            

check_ball_dir_sw:          cmp byte ptr [ball_dir], BALL_DIR_SW
                            jne end_program
                            
                            dec word ptr [ball_x]
                            inc word ptr [ball_y]
                            
                            mov ax, word ptr [rows]
                            sub ax, 2
                            cmp ax, word ptr [ball_y]
                            jne check_ball_dir_sw_wall
                            
                            mov byte ptr [ball_dir], BALL_DIR_NW                      
                            
check_ball_dir_sw_wall:     mov ax, 0
                            cmp ax, word ptr [ball_x]
                            jne check_ball_dir_sw_paddle
                            
                            call draw_ball
                            push 1000
                            call Sleep
                            
                            jmp player_1_lost

check_ball_dir_sw_paddle:   inc ax
                            cmp ax, word ptr [ball_x]
                            jne draw_new_ball
                            
                            mov bx, word ptr [player_1_y]
                            dec bx
                            mov cx, word ptr [ball_y]
                            cmp cx, bx
                            jl draw_new_ball
                            
                            add bx, PADDLE_SIZE
                            cmp cx, bx
                            jg draw_new_ball
                            
                            mov byte ptr [ball_dir], BALL_DIR_SE
                            
                            add cx, 2
                            cmp cx, word ptr [rows]
                            jne check_ball_dir_sw_done
                            
                            mov byte ptr [ball_dir], BALL_DIR_NE
                            
check_ball_dir_sw_done:     call update_tick_interval
                            jmp draw_new_ball

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            
; Keyboard check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            
                            
draw_new_ball:              call draw_ball                          ; Draw the ball
                            
read_key:                   push ESCAPE                             ; If ESCape is pressed...
                            call GetAsyncKeyState
                            cmp ax, 0
                            jne end_program                         ; ..end the program
                            
read_key_cont0:             push PLAYER_1_UP_KEY                    ; Player 1 Up
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont1
                            call player_1_up_pressed
                            
read_key_cont1:             push PLAYER_1_DOWN_KEY                  ; Player 1 Down
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont2
                            call player_1_down_pressed
                            
read_key_cont2:             push PLAYER_2_UP_KEY                    ; Player 2 Up
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont3
                            call player_2_up_pressed
                            
read_key_cont3:             push PLAYER_2_DOWN_KEY                  ; Player 2 Down
                            call GetAsyncKeyState
                            cmp ax, 0
                            je read_key_cont4
                            call player_2_down_pressed
                            
read_key_cont4:             jmp game_loop                           ; Jump back for another game-loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            
; Player loses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                            

player_1_lost:              inc word ptr [player_2_score]           ; Increment Player 2's score
                            call write_player_2_score               ; Print it to screen
                            jmp player_lost                         ; ..and then jump to where we reset the game

player_2_lost:              inc word ptr [player_1_score]           ; Increment Player 1's score
                            call write_player_1_score               ; Print it to the screen, and continue to where we reset the game
                            
player_lost:                call clear_ball                         ; Clear the ball
                            
                            mov dword ptr [tick_interval], DEFAULT_INTERVAL ; Reset the ball tick to slow default value
                            
                            mov ax, word ptr [rows]                 ; Get the number of rows..
                            shr ax, 1                               ; ..bit-shift-right halves the value..
                            mov word ptr [ball_y], ax               ; ..and use it to set the ball y position
                            
                            mov ax, word ptr [cols]                 ; Get the number of columns again..
                            shr ax, 1                               ; ..halve it so we are mid-screen..
                            mov word ptr [ball_x], ax               ; ..and use it to set the ball x position
                           
                            call draw_ball                          ; Draw the ball at it's new, initial position
                            
                            jmp game_loop                           ; Jump back for another game-loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; end_program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end_program:                call clear_screen                       ; Clear the screen 
                            call show_cursor                        ; Show the cursor again
                            push 0                                  ; Exit code zero for success
                            call ExitProcess                        ; https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-exitprocess

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS - FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; update_tick_interval()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_tick_interval:       mov eax, dword ptr [tick_interval]      ; Get the current interval
                            mov ebx, INTERVAL_STEP                  ; Get the step
                            sub eax, ebx                            ; Deduct step from interval..
                            mov dword ptr [tick_interval], eax      ; ..and save it back again
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_1_up_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_1_up_pressed:        mov al, byte ptr [player_1_y]           ; Get the paddle y position
                            cmp al, 0                               ; If at the top..
                            je player_1_up_pressed_done             ; ..then nothing to do

                            dec al                                  ; Move up one row
                            mov byte ptr [player_1_y], al           ; Save our value
                            
                            mov eax, 0                              
                            mov al, byte ptr [player_1_y]           ; Get the y position again
                            add eax, PADDLE_SIZE                    ; Add the size of the paddle
                            mov ebx, 0
                            mov bl, byte ptr [player_1_x]
                            call set_cursor_position                ; Move to where the bottom of the paddle was
                            
                            push SPACE_LEN                          ; ..and overwrite it with a space
                            push offset SPACE
                            call output_string
                            
                            call draw_player_1                      ; Now draw the new paddle

player_1_up_pressed_done:   ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; player_1_down_pressed()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

player_1_down_pressed:      mov ax, word ptr [player_1_y]
                            mov bx, rows
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
                            mov bx, rows
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

write_player_1_score:       mov ax, word ptr [rows]                 ; Find the bottom row
                            dec ax
                            mov bx, word ptr [cols]                 ; Get the number of columns
                            shr bx, 2                               ; Divide by 4 (bit-shift by 2 bits)
                            call set_cursor_position                ; Move the cursor
                            
                            push word ptr [player_1_score]          
                            call output_unsigned_byte               ; Write the score
                            
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; write_player_2_score()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_player_2_score:       mov ax, word ptr [cols]                 ; Get the columns
                            shr ax, 2                               ; Divide by 4
                            mov bx, 3                               ;
                            mul bx                                  ; Multiply by 3
                            mov bx, ax
                            
                            mov ax, word ptr [rows]
                            dec ax
                            
                            call set_cursor_position                ; Move the curor
                            
                            push word ptr [player_2_score]          
                            call output_unsigned_byte               ; Write the score
                            
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw_player_1()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_player_1:              mov eax, 0                              ; Initialise to zero
                            mov ebx, 0
                            mov ax, word ptr [player_1_y]           ; Get the (x, y) for the player
                            mov bx, word ptr [player_1_x]
                            mov ecx, PADDLE_SIZE                    ; Set ECX to paddle size, so we can LOOP
                            
draw_player_1_write_char:   push eax                                ; Save our registers
                            push ebx
                            push ecx
                            call set_cursor_position                ; Move the cursor
                            
                            push BLOCK_LEN                          
                            push offset BLOCK
                            call output_string                      ; Write the block character

                            pop ecx                                 ; Restore our registers
                            pop ebx
                            pop eax
                            
                            inc eax                                 ; Increment to next row
                            loop draw_player_1_write_char           ; ..and loop

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

clear_ball:                 mov eax, 0                              ; Clear our registers
                            mov ebx, 0
                            mov al, byte ptr [ball_y]               ; Get the ball (x, y)
                            mov bl, byte ptr [ball_x]
                            
                            push eax                                ; Save our registers
                            push ebx
                            call set_cursor_position                ; Move the cursor
                            pop ebx                                 ; Restore our registers
                            pop eax

                            push SPACE_LEN
                            push offset SPACE
                            call output_string                      ; Write the space to overwrite the old ball
                            
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

get_console_settings:       lea eax, [console_buffer_info]          ; Point to struct
                            push eax
                            push console_out_handle                            
                            call GetConsoleScreenBufferInfo         ; Get the data we need
                            
                            mov ax, word ptr [console_buffer_info.srWindow.Right]   ; Get the window width..
                            mov bx, word ptr [console_buffer_info.srWindow.Left]    ; ..and left position
                            sub ax, bx                                              ; Subtract to get cols
                            inc ax
                            mov word ptr [cols], ax                                 ; ..and save
                            
                            mov ax, word ptr [console_buffer_info.srWindow.Bottom]  ; Get the window height..
                            mov bx, word ptr [console_buffer_info.srWindow.Top]     ; ..and right position
                            sub ax, bx                                              ; Subtract to get rows
                            inc ax
                            mov word ptr [rows], ax                                 ; ..and save
                            
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hide_cursor()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_cursor:                mov dword ptr [cursor_info.dwSize], 20                  ; Set cursor size to 20
                            mov dword ptr [cursor_info.bVisible], 0                 ; ..and hide
                            lea eax, [cursor_info]
                            push eax
                            push console_out_handle
                            call SetConsoleCursorInfo
                            
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; show_cursor()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_cursor:                mov dword ptr [cursor_info.dwSize], 20                  ; Set cursor size to 20
                            mov dword ptr [cursor_info.bVisible], 1                 ; ..and show
                            lea eax, [cursor_info]
                            push eax
                            push console_out_handle
                            call SetConsoleCursorInfo
                            
                            ret
                            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set_cursor_position(ax = y, bx = x)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_position:        shl eax, 16                                             ; Shift-left to make room for bx
                            mov ax, bx
                            push eax
                            push console_out_handle
                            call SetConsoleCursorPosition                           ; Set the position
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_string()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_string:              pop ebp                                                 ; Pop the return address
                            pop esi                                                 ; Pop length-of-string into edi
                            pop edi                                                 ; Pop offset-of-string into esi
                            
                            push 0                                                  ; _Reserved_      LPVOID  lpReserved
                            push offset bytes_written                               ; _Out_           LPDWORD lpNumberOfCharsWritten
                            push edi                                                ; _In_            DWORD   nNumberOfCharsToWrite
                            push esi                                                ; _In_      const VOID *  lpBuffer
                            push console_out_handle                                 ; _In_            HANDLE  hConsoleOutput
                            call WriteConsole                                       ; https://docs.microsoft.com/en-us/windows/console/writeconsole

                            push ebp                                                ; Restore return address
                            ret                                                     ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output_unsigned_byte(BYTE: number)
; Destroys: EBP, 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

output_unsigned_byte:       pop ebp                                                 ; Pop the return address
                            pop ax                                                  ; Pop integer to output into AX
                            push ebp                                                ; Push EBP back onto stack

                            and ax, 00FFh                                           ; Make sure AX is in range 0..255                    
                            mov ecx, 0                                              ; Set digits counter to zero     
                    
output_unsigned_byte_perform_calculation:                    
                            mov dx, 0
                            mov bx, 10                                              ; Divide by 10
                            div bx                                                  ; Divide AX by BX                    
                                                                                    ; DL contains remainer, AL contains quotient
                            and edx, 000000FFh                                      ; Make sure EDX (remainer) is in range 0..255
                            add dl, 030h                                            ; Add 30h (the letter '0' (zero)) so we map numbers to letters
                            push dx                                                 ; Push our letter to the stack
                            inc ecx                                                 ; Increment digit counter

                            cmp al, 0                                               ; Check if quotient is zero
                            jne output_unsigned_byte_perform_calculation            ; If quotient is not zero, then we need to perform the operation again

                            mov edi, 0                                              ; Set EDI to zero. This will point to 'number_buffer' starting at index 0
output_unsigned_byte_finished_calculation:
                            pop dx                                                  ; Read the last remainder from the stack
 
                            mov byte ptr [number_buffer + edi], dl                  ; Copy the letter to 'number_buffer'
                    
                            inc edi                                                 ; Incrememnt out pointer to 'number_buffer'
                            loop output_unsigned_byte_finished_calculation          ; Continue looping until ECX is zero

                            push edi                                                ; At the end of the process, EDI will conveniently hold the number of characters written to 'number_buffer'. Pass it as a parameter to 'output_string'
                            push offset number_buffer
                            call output_string      
  
                            ret                                                     ; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; clear_screen()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_screen:               mov eax, 0                                              ; Initialise to zero
                            mov ebx, 0
                            
clear_screen_col_loop:      push eax                                                ; Save our registers
                            push ebx
                            call set_cursor_position                                ; Move to position
                            pop ebx
                            pop eax

                            push eax
                            push ebx
                            push SPACE_LEN
                            push offset SPACE                                       ; Write the space
                            call output_string 
                            pop ebx
                            pop eax
                            
                            inc ebx                                                 ; Check to see if at end of column
                            cmp bx, word ptr [cols]
                            jne clear_screen_col_loop                               ; Keep looping if not
                            
                            mov ebx, 0                                              ; Reset column to 0
                            inc eax                                                 ; ..and increment row
                            cmp ax, word ptr[rows]                                  ; Check if at bottom..
                            jne clear_screen_col_loop                               ; ..and if not, keep looping
                            
                            mov ax, 0                                               ; Finally, reset the cursor to (0,0)
                            mov bx, 0
                            call set_cursor_position
                            ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get_output_handle()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_output_handle:          push STD_OUTPUT_HANDLE                  ; _In_ DWORD nStdHandle
                            call GetStdHandle                       ; https://docs.microsoft.com/en-us/windows/console/getstdhandle
                            mov [console_out_handle], eax           ; Save the output handle
                            ret
                    
end start