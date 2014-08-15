.8086
.model small, nearstack

crlf equ 0Ah,0Dh

extern get_command_line:near, io_init:near, print_str:near, flush_manual:near,
	str_token:near, hex_to_ascii:near, io_init:near, print_str:near, flush_manual:near

.code
.startup
	mov ah, 0Fh
	int 10h
	mov video_mode, al
	mov old_video_page, bh
	;cmp al, 0
	mov al, 01h
	mov ah, 5
	int 10h
	
	mov ax, 0900h ;Fill characters
	mov bx, 0117h ;Video page 1, blue background, gray foreground
	mov cx, 80*25
	int 10h
	
	;Reset cursor and give new attributes to line 0
	mov dx, 0000h
	mov ah, 02h
	mov bh, 01h
	int 10h
	
	mov ax, 0900h
	mov bx, 0170h ;Video page 1, grey background, black foreground
	mov cx, 80
	int 10h
	
	mov ax, str_buffers ;@fardata doesn't work, even in JWASM- in int10h mode,
				;ES needs to be set appropriately before entering
				;the function (because finer control may be needed).
	mov es, ax
	call io_init
	mov ax, @data
	mov ds, ax
	mov si, offset msg_menu
	call print_str
	call flush_manual
	
	


;fill_background proc

;fill_background endp

.exit 0
.data

.data?
using_color db ?
video_mode db ?
old_video_page db ?


.const
msg_menu db 'File Search Options Help', 0
msg_invalid db 'Invalid video mode', crlf, '$'
valid_vmodes db 00h, 01h, 02h, 03h, 07h

.fardata? str_buffers

.fardata? hex_buffer

.stack


end
