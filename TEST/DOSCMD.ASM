.8086
.model small, nearstack

crlf equ 0x0D0A

extern get_command_line:near, io_init:near, print_str:near, flush_manual:near

.code
.startup
	;DS=>DGROUP, CS=>ERROR by using simplified segments.
	call io_init
	mov ax, offset command_line_ptr
	push ax
	call get_command_line
	add sp, 0x02
	mov si, command_line_ptr ;DS:SI ready
	call print_str
	call flush_manual
	mov si, offset msg_token_start
	call print_str
	call flush_manual
	
	;str_token parsing goes here.
	
.exit 0

.const
msg_token_start db 'Here are the tokens...', crlf, 0
msg_token	db 'Token #', 0

.data
token_no_ascii	db 0, 0, crlf, 0 ;1 byte hex => 2 bytes ASCII

.data?
command_line_ptr dw ?

.stack

end
