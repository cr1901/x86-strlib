.8086
.model small, nearstack

crlf equ 0Ah,0Dh

extern get_command_line:near, io_init:near, print_str:near, flush_manual:near,
	str_token:near, hex_to_ascii:near

.code
.startup
	;DS=>DGROUP, CS=>ERROR by using simplified segments.
	call io_init
	mov ax, offset cl_length
	push ax
	call get_command_line
	add sp, 2
	mov si, ax ;DS:SI ready
	mov command_line_ptr, ax ;We need the beginning of the buffer later
	call print_str
	call flush_manual
	mov si, offset msg_token_start
	call print_str
	call flush_manual
	
	;str_token parsing goes here.
	;Push all nears, but str_token uses fars.
	push ds ;Seg token_buf
	mov si, offset token_buf
	push si
	push ds
	mov si, offset dl_with_crlf
	push si
	push ds
	mov si, command_line_ptr
	push si
	
	xor bx, bx ;CX is not guaranteed to be valid between calls to str_token.
		;Technically, neither is DX, but it's not used. I wonder if a modern
		;compiler would recognize that?
next_tok:	
	;Get a token
	call str_token
	mov si, offset msg_token
	call print_str
	;call flush_manual
	
	;Print token number
	push ax
	push bx
	call hex_to_ascii
	mov token_no_ascii + 1, ah ;LSB First
	mov token_no_ascii, al	;Then MSB
	mov si, offset token_no_ascii
	call print_str
	add sp, 2
	pop ax
	
	;Print the token
	mov si, offset token_buf
	call print_str
	mov si, offset msg_newline
	call print_str

	test ax, 0FFFFh
	jz done_parse
	pop dx
	add dx, ax		;Other buffers stay the same, "push" new offset
	push dx
	inc bx
	jmp next_tok
	
done_parse:
	sub sp, 12 ;6 words
	mov si, offset msg_done
	call print_str
	call flush_manual
	
.exit 0

.const
msg_token_start db 'Here are the tokens...', crlf, 0
msg_token	db 'Token #', 0
msg_done	db 'Done parsing tokens...', crlf, 0
msg_newline	db crlf, 0

.data
token_no_ascii	db 0, 0, crlf, 0 ;1 byte hex => 2 bytes ASCII
dl_space db ' ', 0
dl_with_crlf db ' ', crlf, 0

.data?
cl_length db ?
command_line_ptr dw ?
token_buf db 128 dup(?)

.stack

end
