.8086
.model small, nearstack

crlf equ 0Ah,0Dh

extern hex_to_ascii:near, get_command_line:near, print_str:near,
	io_init:near ;, ascii_to_hex:near

;Swap AX and DX return values of Hex to Ascii?

;No- return as if multibyte character sequence.
;http://stackoverflow.com/questions/1568057/ascii-strings-and-endianness
	
.code
.startup
	xor ax, ax
next_val:
	push ax
	call hex_to_ascii
	xchg dh, dl ;Correct for endianness
	xchg ah, al
	mov word ptr [ascii_bufw], dx
	mov word ptr [ascii_bufw + 2], ax
	pop ax
	inc ax
	jnz next_val
	
.exit 0

.const
msg_cmdline 	db 'The input command line was: ', 0
msg_token_start db 'Here are the tokens...', crlf, 0
msg_token	db 'Token #', 0
msg_done	db 'Done parsing tokens...', crlf, 0
msg_newline	db crlf, 0

.data
token_no_ascii	db 0, 0, crlf, 0 ;1 byte hex => 2 bytes ASCII
dl_space db ' ', 0
dl_with_crlf db ' ,', crlf, 0

.data?
value_bufw dw ?
value_bufd dd ?
ascii_bufb dw ?
ascii_bufw dd ?
ascii_bufd dd 2 dup(?)

.stack

end
