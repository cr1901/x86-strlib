.8086
ifdef __DOS__
	.model small, nearstack
else
	.model small
endif

;This module provides an I/O interface, depending on OS (none or DOS).
;Move all buffers to I/O, export all but string buffer.

;What happens when?...
;Two segments with the same name, one public, one private, and the segment name is included into a group?
;Two segments with the same name, but different classes, and the segment name is included into a group?
;Multiple segments with different names, have the same class, but only some of these segments are placed into a group? (Explained in manual)

public io_init, print_str, flush_manual

bufsiz equ 20h

.code
;Inputs to this function may vary depending on application.
;Example: ES could be set internally, externally, or could be an input!
;For the monitor, ES is set externally. See commented code for example for
;other versions.
io_init proc near
	push bp
	mov bp, sp
	push di
	
	;Input version
	;mov ax, [bp + 0x02]
	;mov es, ax
	
	;Internal version
	;mov ax, bss_seg ;or @fardata
	;mov es, ax
	
	ifdef __DOS__
		mov ax, far_bss		;mov ax, @fardata?
		mov es, ax	
		assume es:far_bss
		;mov es:[string_tail], offset string_buffer
		;mov di, offset string_buffer
	else
		assume es:bss_seg
		;mov es:[string_tail], offset string_buffer
		;mov di, offset string_buffer
	endif
	
	mov es:[string_tail], offset string_buffer
	mov di, offset string_buffer
	
	mov al, 0
	mov cx, bufsiz
	shr cx,1         ;adjust for words
	rep stosw        ;copy words
	adc cx,cx        ;cx=0 if even, cx=1 if odd
	rep stosb        ;copies nothing if cx=0; copies 1 byte if cx=1

	pop di
	mov sp, bp
	pop bp
	ret
io_init endp





;Inputs:
;BH- Page Number
;BL- Foreground Color
;DS:SI- String to print
;Returns: 
;Registers are preserved (or should be, barring bug in INT 0x10).
;Assumes: ES points to the string buffer's segment (ROM version).
print_str proc near
	push ax
	push cx
	push dx ;DX trashed by flush_buffer
	push bp ;BP can be destroyed due to bug when scrolling.
	push di
	push si
	push es

	;DOS Version
	ifdef __DOS__
		mov ax, far_bss		;mov ax, @fardata? for MASM 5.x
		mov es, ax
		
		;If not using .fardata? the segment override in mov di, ... can be eliminated!
		assume es:far_bss
	else
		;ROMable version makes other assumptions, so above two instructions
		;aren't needed!
		assume es:bss_seg
	endif
	
	mov di, es:[string_tail]
	
next_char:
	;delay
	;test byte ptr [si], 0xFF
	cmp byte ptr [si], 0 ;Check for null-terminator
	;jmp end_str
	jz end_str
	
	cmp word ptr [si], 0D0Ah ;Check for newline
	jnz no_newline
	movsw
	call flush_buffer
	jmp next_char ;In case 0x00 is next
no_newline:

	;Check for tab character- convert to 5 spaces. Add to io.asm in monitor
	;source files.
no_tab:

	cmp di, offset string_buffer + bufsiz ;Check that buffer is full 
	jl no_flush
	call flush_buffer
no_flush:	
	movsb
	jmp next_char
end_str:
	mov es:[string_tail], di
	pop es
	pop si
	pop di
	pop bp
	pop dx
	pop cx
	pop ax
	ret
print_str endp

;__cdecl void cprint_str(char __far *)
;C-callable print_str
cprint_str proc near
	fp_seg equ word ptr ss:[6 + bp]
	fp_off equ word ptr ss:[4 + bp]
	
	push bp
	mov bp, sp
	push si
	push ds
	lds si, dword ptr fp_off
	call print_str
	pop ds
	pop si
	mov sp, bp
	pop bp
	ret
cprint_str endp



;Returns: Clear Reset DI
;Trashes: AX, DX
;Assumes: ES points to the string buffer's segment.
;BX holds Page number/Foreground combination.
;Direction flag is cleared (though this module doesn't change it).
;
;The last string in the program should flush the buffer with a newline.
;This is because, for speed considerations, the buffer looks at DI instead of
;string_tail to determine where to place a terminator and DI may not be valid
;outside this module (hence flush_buffer is private).

;Note to myself after not looking at this for a few months... is the above
;paragraph still valid?
flush_buffer proc near
	;push si
	push ds
	mov ax, es
	mov ds, ax ;String buffer now becomes the source string.
	
	mov cx, di ;DI holds the current tail.
	sub cx, offset string_buffer
	jz dont_bother ;If tail = buffer_offset, looping will loop 0xFFFF times!
			;This check SHOULD only be relevant when flush_manual is called.



ifdef __DOS__
	mov dx, offset string_buffer
	;mov byte ptr [di], 0xB2 ;Symbol char- for debugging purposes
	;mov byte ptr [di + 1], '$'
	mov byte ptr [di], '$'
	mov ah, 9h
	int 21h
	;mov si, dx For DOS, preserving SI not required in this routine...
	;int 21h expects DS:DX instead- DX is still trashed.
	
else
	mov dx, si ;Retain the old value of SI. DX is trashed.
	mov si, offset string_buffer
	mov ah, 0Eh ;Teletype output
flush_next:	
	lodsb ;al now holds character to print
	int 10h
	;delay
	loop flush_next
	mov si, dx ;Restore SI
endif

	mov di, offset string_buffer ;Reset the string tail	
dont_bother:	
	pop ds
	;pop si
	ret
flush_buffer endp


;Returns: Clear Reset DI
;Trashes: AX, DX
;The last string in the program should flush the buffer with a newline.
;This is because, for speed considerations, the buffer looks at DI instead of
;string_tail to determine where to place a terminator and DI may not be valid
;outside this module (hence flush_buffer is private).
;flush_buffer proc near
;	mov dx, offset string_buffer
;	;mov [di], 0xB2 ;Symbol char
;	;mov [di + 1], '$'
;	mov [di], '$'
;	mov ah, 0x09
;	int 0x21
;	mov di, offset string_buffer
;	ret
;flush_buffer endp


;Returns: Clear Reset DI
;Trashes: AX, DX
;Assumes: ES points to the string buffer's segment (ROM version).
;A user should flush the buffer manually with this function.
;This is because, for speed considerations, the buffer looks at DI instead of
;string_tail to determine where to place a terminator. DI may not be valid
;outside this module (hence flush_buffer is private).
flush_manual proc near

	;DOS Version
	ifdef __DOS__
		mov ax, far_bss		;mov ax, @fardata? for MASM 5.x
		mov es, ax
		
		;If not using .fardata? the segment override in mov di, ... can be eliminated!
		assume es:far_bss
	endif
	
	mov di, es:[string_tail]
	;mov [di], 0xB1 ;Symbol char
	;inc di
	call flush_buffer
	mov es:[string_tail], di
	ret
flush_manual endp


;string_tail is the "next free" location
ifdef __DOS__
	.fardata?
	string_tail dw ?
	string_buffer db (bufsiz + 1) dup(?)
	
else
	bss_seg segment word public 'FAR_BSS'
		string_tail dw ?
		string_buffer db (bufsiz + 1) dup(?)
	bss_seg ends
endif	

end
