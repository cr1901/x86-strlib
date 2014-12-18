cpu 8086
%include "MACROS.ASM"

%define crlf 13, 10


extern get_command_line, io_init, print_str, flush_manual, \
	str_token, hex_to_ascii, ZTimerOn, ZTimerOff, ZTimerReport
	
group dgroup data bss const

segment code class=CODE

..start: ;..start is a special entry-point symbol
	mov ax, dgroup
	mov ds, ax
	mov ax, stack
	mov ss, ax
	mov sp, stacktop
	
	call io_init
	mov si, msg_banner
	call print_str
	mov ax, cl_length
	push ax
	call get_command_line
	add sp, 2
	mov si, ax ;DS:SI ready for tokenizing
	mov [command_line_ptr], ax ;We need the beginning of the buffer later
	
	;Ready to parse command line
	pushfp ds, token_buf
	pushfp ds, cl_delims
	multipush ds, si ;Input str buffer
	call far str_token
	add sp, 12
	
	;Take the token and attempt to open a file
	mov ax, 3D00h
	mov dx, token_buf
	int 21h
	jc file_bad

;It appears ZTimer cannot be called more than once per application- likely due
;to using global state.
;	mov si, token_buf
;	call print_str
;	mov si, msg_exists
;	call print_str
;	
;	;Read first 128 bytes into buffer and parse tokens
;	;call ZTimerOn
;	mov bx, ax
;more_data:
;	mov ah, 3Fh
;	mov cx, 80h
;	mov dx, file_buf
;	int 21h
;	mov byte ptr [num_bytes_asked], cl
;	mov byte ptr [num_bytes_read], al
;	;call str_token goes here
;	
;	;Reset str_token pointer- simulation
;	add sp, 2
;	mov si, file_buf
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
	pushfp ds, token_buf
	pushfp ds, cl_delims
	pushfp ds, file_buf
	
	;BX still holds handle
	;call ZTimerOn
more_data2:
	mov ah, 3Fh
	mov cx, 80h
	mov dx, file_buf
	int 21h
	mov byte [num_bytes_asked], cl
	mov byte [num_bytes_read], al
	
	;Add null terminator to end, regardless of the number of bytes read!
	xor ah, ah
	mov si, ax
	mov byte [file_buf + si], 0
	;str_token goes here

next_tok:	
	call far str_token
	
	pop dx ;Previous offset		
	push ax ;New offset. Other buffers stay the same, "push" new offset
	
	cmp ax, dx ;If they are equal, then strtok found nothing.
	
	if ne
		mov si, token_buf
		call print_str
		mov si, msg_newline
		call print_str
		jmp next_tok
	else
		mov si, msg_newline
		call print_str	
	endif
	
	;jne next_tok
	;call flush_buffer
	
	;Reset str_token pointer
	add sp, 2
	mov si, file_buf
	push si
	
	mov cl, byte [num_bytes_asked]
	mov al, byte [num_bytes_read]
	cmp cl, al
	je more_data2
	
	add sp, 12 ;Restore stack
	;call ZTimerOff ;This becomes overhead
	;call ZTimerReport
	
	mov ax, 4c00h
	int 21h

file_bad:
	mov si, token_buf
	call print_str
	mov si, msg_noexist
	call print_str
	
	push ax
	call hex_to_ascii
	xchg ah, al ;Prepare to store value
	mov si, msg_error
	;Load error code into AX- no assumes needed since this is small model
	;mov word [(error_code - msg_error) + si], ax
	call print_str
	
	mov ax, 4c01h
	int 21h

segment const class=DATA
msg_banner db 'DOSREAD STRLIB Test Utility', crlf, 0
msg_read db 'Reading input file...', crlf, 0
msg_newline db crlf, 0
cl_delims db ' ', crlf, 0
msg_exists db ' exists.', crlf, 0
msg_noexist db ' does not exist!', crlf, 0
;msg_error db ' Error Code'

segment data class=DATA
msg_error db 'DOS Error Code '
error_code dw 0
db crlf, 0 ;Add null


segment bss class=BSS
cl_length resb 1
command_line_ptr resw 1
token_buf resb 80h
file_buf resb 81h
num_bytes_asked resb 1
num_bytes_read resb 1

;Some linkers will complain if a class called StAcK (case-insensitive) 
;isn't found.
segment stack stack class=STACK
	resb 200h
stacktop:

