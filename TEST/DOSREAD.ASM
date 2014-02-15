.8086
.model small, nearstack

crlf equ 0Ah,0Dh

extern get_command_line:near, io_init:near, print_str:near, flush_manual:near,
	str_token:near, hex_to_ascii:near, ZTimerOn:far, ZTimerOff:far, ZTimerReport:far
	
.code
.startup
	call io_init
	mov si, offset msg_banner
	call print_str
	mov ax, offset cl_length
	push ax
	call get_command_line
	add sp, 2
	mov si, ax ;DS:SI ready for tokenizing
	mov command_line_ptr, ax ;We need the beginning of the buffer later
	
	;Ready to parse command line
	push ds ;Output buffer
	mov si, offset token_buf
	push si
	push ds ;Delimiter buffer
	mov si, offset cl_delims
	push si
	push ds ;Input str buffer
	push ax
	call str_token
	add sp, 12
	
	;Take the token and attempt to open a file
	mov ax, 3D00h
	mov dx, offset token_buf
	int 21h
	jc file_bad

;It appears ZTimer cannot be called more than once per application- likely due
;to using global state.
;	mov si, offset token_buf
;	call print_str
;	mov si, offset msg_exists
;	call print_str
;	
;	;Read first 128 bytes into buffer and parse tokens
;	;call ZTimerOn
;	mov bx, ax
;more_data:
;	mov ah, 3Fh
;	mov cx, 80h
;	mov dx, offset file_buf
;	int 21h
;	mov byte ptr [num_bytes_asked], cl
;	mov byte ptr [num_bytes_read], al
;	;call str_token goes here
;	
;	;Reset str_token pointer- simulation
;	add sp, 2
;	mov si, offset file_buf
;	push si
;	mov cl, byte ptr [num_bytes_asked]
;	mov al, byte ptr [num_bytes_read]
;	cmp al, cl
;	je more_data
	;call ZTimerOff ;This becomes overhead
	;call ZTimerReport
	
	
	;Reset file
;	mov ax, 4200h
;	xor cx, cx
;	xor dx, dx
;	int 21h
	
	mov bx, ax ;Preserve file handle!
	;Ready to parse tokens in file for real test
	push ds ;Output buffer
	mov si, offset token_buf
	push si
	push ds ;Delimiter buffer
	mov si, offset cl_delims
	push si
	push ds ;Input str buffer
	mov si, offset file_buf
	push si
	
	;BX still holds handle
	call ZTimerOn
more_data2:
	mov ah, 3Fh
	mov cx, 80h
	mov dx, offset file_buf
	int 21h
	mov byte ptr [num_bytes_asked], cl
	mov byte ptr [num_bytes_read], al
	;str_token goes here

next_tok:	
	call str_token
	mov si, offset token_buf
	call print_str
	mov si, offset msg_newline
	call print_str
	
	pop dx
	add dx, ax		;Other buffers stay the same, "push" new offset
	push dx
	test ax, 0FFFFh
	jnz next_tok
	;call flush_buffer
	
	;Reset str_token pointer
	add sp, 2
	mov si, offset file_buf
	push si
	
	mov cl, byte ptr [num_bytes_asked]
	mov al, byte ptr [num_bytes_read]
	cmp cl, al
	je more_data2
	add sp, 12 ;Restore stack
	call ZTimerOff ;This becomes overhead
	call ZTimerReport
	
	
	
	;mov ax, bx
	

.exit

file_bad:
	mov si, offset token_buf
	call print_str
	mov si, offset msg_noexist
	call print_str
	
	push ax
	call hex_to_ascii
	mov si, offset msg_error
	;Load error code into AX- no assumes needed since this is small model
	mov word ptr [(error_code - msg_error) + si], ax
	call print_str

.exit 1

.const
msg_banner db 'DOSREAD STRLIB Test Utility', crlf, 0
msg_read db 'Reading input file...', crlf, 0
msg_newline db crlf, 0
cl_delims db ' ', crlf, 0
msg_exists db ' exists.', crlf, 0
msg_noexist db ' does not exist!', crlf, 0
;msg_error db ' Error Code'

.data
msg_error db 'DOS Error Code '
error_code dw 0
	db crlf, 0 ;Add null


.data?
cl_length db ?
command_line_ptr dw ?
token_buf db 128 dup(?)
file_buf db 129 dup(?)
num_bytes_asked db ?
num_bytes_read db ?

.stack

end
