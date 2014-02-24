.8086
.model small, nearstack

crlf equ 0Ah,0Dh

extern get_command_line:near, io_init:near, print_str:near, flush_manual:near,
	str_token:near, hex_to_ascii:near

close_file macro
	mov ah, 3Eh
	int 21h
endm
	
	
;Segment names are treated as addresses in mov ax, segment... as opposed to 
;mov ax, [variable] = mov ax, [variable] for other data types where is this speficied
;in MASM manual?
bios_seg segment at 0F000h

bios_seg ends
	
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
	
	;mov di, sp	;We need an index register to directly modify the stack
	;cmp ax, ss:[di] ;The stack pointer currently points to the input fp buffer offset.
	;		;Check if we are at the end of the string- DX:AX will equal
	;		;the input pointer on the stack if we are at the end.
	;jne file_ok
	;add di, 2
	;cmp dx, ss:[di]
	;je no_file_provided
	add sp, 8
	pop di
	pop es ;Check the filename token
	;http://www.int80h.org/strlen/
	xor cx, cx
	not cx
	xor al, al
	repne scasb
	not cx
	dec cx
	jz no_filename_provided
	
filename_ok:	
	;Take the token and attempt to open a new file
	mov ah, 3Ch
	xor cx, cx ;No special attributes
	mov dx, offset token_buf ;DS points to write place
	int 21h
	jc file_bad
	mov si, offset msg_dump
	call print_str
	mov si, offset token_buf
	call print_str
	mov si, offset msg_newline
	call print_str
	
	mov bx, ax ;Preserve file handle
	mov ax, bios_seg ;mov ax, [bios_seg]
	mov ds, ax
	assume ds:bios_seg
	xor dx, dx
	mov cx, 08000h
	mov ah, 40h ;Write 32768 bytes to file.
	int 21h
	cmp cx, ax
	jne disk_full
	add dx, ax ;Increment the BIOS segment pointer by AX (8000h) bytes.
	mov ah, 40h ;Write the next 32768 bytes to file.
	int 21h
	cmp cx, ax
	jne disk_full
	
	mov dx, @data
	mov ds, dx
	assume ds:@data
	mov si, offset msg_success1
	call print_str
	mov si, offset token_buf
	call print_str
	mov si, offset msg_success2
	call print_str
	close_file
	
	
;more_data2:
	;mov ah, 3Fh
	;mov cx, 80h
	;mov dx, offset file_buf
	;int 21h
	;mov byte ptr [num_bytes_asked], cl
	;mov byte ptr [num_bytes_read], al
	;str_token goes here
	;call flush_buffer
	
	
	
	;mov ax, bx
	

.exit

	;Put the original assume back, just in as things depend on it...
	;error_code - msg_error should, and yet no error occurs when I don't put
	;it. Why not?
	assume ds:@data
file_bad:
	mov si, offset msg_errcreat
	call print_str
	mov si, offset token_buf
	call print_str
	mov si, offset msg_newline
	call print_str
	
	push ax
	call hex_to_ascii
	mov si, offset msg_error
	;Load error code into AX- no assumes needed since this is small model
	mov word ptr [(error_code - msg_error) + si], ax
	call print_str
	close_file
.exit 1

no_filename_provided:
	mov si, offset msg_provide
	call print_str
.exit 1

disk_full:
	mov dx, @data
	mov ds, dx
	assume ds:@data
	mov si, offset msg_noroom
	call print_str
	close_file
.exit 1


.const
msg_banner db 'BIOSDUMP STRLIB Test Utility', crlf, 0
msg_read db 'Reading input file...', crlf, 0
msg_newline db crlf, 0
msg_errcreat db 'Error creating ', 0
cl_delims db ' ', crlf, 0
msg_dump db 'Dumping BIOS to ', 0
msg_exists db ' exists.', crlf, 0
msg_noexist db ' does not exist!', crlf, 0
msg_provide db 'Need to provide an output filename.', crlf, 0
msg_noroom db 'File write failed on current drive. Perhaps the disk is full?', crlf, 0
msg_success1 db 'BIOS written to ', 0
msg_success2 db 'successfully.', crlf, 0

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
