.8086
ifdef __DOS__
	.model small, nearstack
else
	.model small
endif

;How to export subroutines where call distance is not known ahead of time?
public str_token:near, get_command_line:near

.code
;uint16_t __cdecl str_token(char * __far str, char * __far delim, char * __far outbuf);
str_token proc near
	;__cdecl stack
	instr_seg equ ss:[0x0E + bp]
	instr_offset equ ss:[0x0C + bp]
	delim_seg equ ss:[0x0A + bp]
	delim_offset equ ss:[0x08 + bp]
	outbuf_seg equ ss:[0x06 + bp]
	outbuf_offset equ ss:[0x04 + bp]
	
	push bp
	mov bp, sp
	push bx
	push si
	push di
	push ds
	push es
	
	mov ax, instr_seg
	mov ds, ax
	mov bx, delim_offset
	
	
	
	pop es
	pop ds
	pop di
	pop si
	pop bx
	mov sp, bp
	pop bp
	ret
str_token endp


;Stores a copy of the DOS command line in a near buffer (inside DGROUP).
;Do not use in ROMable mode (for now)!
;uint8_t __cdecl get_command_line(char ** __near)
;Input: Address of __near pointer which points to the buffer where DOS command line
;is stored.
;Return: AL- Length of Command Line
;Preserves- All registers besides CX
get_command_line proc near
	;__cdecl stack
	buffer_near_ptr equ word ptr ss:[0x04 + bp]
	
	push bp
	mov bp, sp
	push bx
	push ds
	push es
	
	mov ah, 0x51
	int 0x21 ;Get PSP segment
	mov ds, bx
	mov si, 0x81 ;Start of command-line
	mov ax, @data ;Alias for DGROUP
	mov es, ax 
	assume es:@data ;Actually, this assume might not be necessary
	mov di, offset command_tail
	mov bx, buffer_near_ptr	
	mov es:[bx], di ;Return a pointer to the command tail of the PSP. Since
			;DS doesn't point to the correct place, segment override
			;is used.
	mov al, byte ptr ds:[0x80] ;Length of command line is stored here
	mov cl, al
	rep movsb
	pop es
	pop ds
	pop bx
	
	mov sp, bp
	pop bp
	ret
get_command_line endp

.data?
command_tail db 128 dup(?)	;Why are contents retained between invocations?
ct_end:

end
