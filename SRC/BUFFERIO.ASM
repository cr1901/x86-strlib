cpu CPU_TARGET
%include "MACROS.ASM"

bufsiz equ 20h

global io_init, print_str, flush_manual

;Inputs to this function may vary depending on application.
;Example: ES could be set internally, externally, or could be an input!
;For the monitor, ES is set externally. See commented code for example for
;other versions.

io_init:
	prolog
	multipush di, es
	
	;Input version
	;mov ax, [bp + 0x02]
	;mov es, ax
	
	;Internal version
	;mov ax, bss_seg ;or @fardata
	;mov es, ax
	
%ifidni HOST_ENV, INT21H
	mov ax, far_bss		;mov ax, @fardata?
	mov es, ax
%endif
	
	mov [es:string_tail], word string_buffer
	mov di, string_buffer
	
	xor ax, ax
	mov cx, bufsiz
	shr cx,1         ;adjust for words
	rep stosw        ;copy words
	adc cx,cx        ;cx=0 if even, cx=1 if odd
	rep stosb        ;copies nothing if cx=0; copies 1 byte if cx=1
	
	multipop di, es
	epilog
	ret
	
;Inputs:
;BH- Page Number
;BL- Foreground Color
;DS:SI- String to print
;Returns: 
;Registers are preserved (or should be, barring bug in INT 0x10).
;Assumes: ES points to the string buffer's segment (ROM version).
print_str:
	multipush ax, cx, dx, bp, di, si, es ;DX trashed by flush_buffer
	;BP can be destroyed due to bug when scrolling.

	;DOS Version
%ifidni HOST_ENV, INT21H
		mov ax, far_bss		;mov ax, @fardata? for MASM 5.x
		mov es, ax ;If not using .fardata? the segment override in mov di, ... can be eliminated!
%endif
	;ROMable version makes other assumptions, so above two instructions
	;aren't needed!
	mov di, [es:string_tail]
	
next_char:
	;delay
	;test byte ptr [si], 0xFF
	cmp byte [si], 0 ;Check for null-terminator
	;jmp end_str
	jz end_str
	
	;cmp byte [si], 0x0A0D is likely faster in most cases, but I'm
	;not fond of unaligned accesses.
	cmp byte [si], 0x0D ;Check for newline
	jnz no_newline
	cmp byte [si + 1], 0x0A ;Check for newline
	jnz no_newline
	movsw
	call flush_buffer
	jmp next_char ;In case 0x00 is next
no_newline:

	;Check for tab character- convert to 5 spaces. Add to io.asm in monitor
	;source files.
no_tab:

	cmp di, string_buffer + bufsiz ;Check that buffer is full 
	jl no_flush
	call flush_buffer
no_flush:	
	movsb
	jmp next_char
end_str:
	mov [es:string_tail], di
	multipop ax, cx, dx, bp, di, si, es
	ret

;__cdecl void cprint_str(char __far *)
;C-callable print_str
cprint_str:
;%push cprint_str_context
;%arg fp_seg:word
;%arg fp_off:word
	defargs near, fp_off, 2, fp_seg, 2

	prolog
	multipush si, ds
	lds si, [fp_off]
	call print_str
	multipop si, ds
	epilog
	ret
;%pop



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
flush_buffer:
	;push si
	push ds
	mov ax, es
	mov ds, ax ;String buffer now becomes the source string.
	
	mov cx, di ;DI holds the current tail.
	sub cx, string_buffer
	jz dont_bother ;If tail = buffer_offset, looping will loop 0xFFFF times!
			;This check SHOULD only be relevant when flush_manual is called.



%ifidni HOST_ENV, INT21H
	mov dx, string_buffer
	;mov byte ptr [di], 0xB2 ;Symbol char- for debugging purposes
	;mov byte ptr [di + 1], '$'
	mov byte [di], '$'
	mov ah, 9h
	int 21h
	;mov si, dx For DOS, preserving SI not required in this routine...
	;int 21h expects DS:DX instead- DX is still trashed.
	
%else
	mov dx, si ;Retain the old value of SI. DX is trashed.
	mov si, string_buffer
	mov ah, 0Eh ;Teletype output
flush_next:	
	lodsb ;al now holds character to print
	int 10h
	;delay
	loop flush_next
	mov si, dx ;Restore SI
%endif

	mov di, string_buffer ;Reset the string tail	
dont_bother:	
	pop ds
	;pop si
	ret


;Returns: Clear Reset DI
;Trashes: AX, DX
;Assumes: ES points to the string buffer's segment (ROM version).
;A user should flush the buffer manually with this function.
;This is because, for speed considerations, the buffer looks at DI instead of
;string_tail to determine where to place a terminator. DI may not be valid
;outside this module (hence flush_buffer is private).
flush_manual:
	;DOS Version
%ifidni HOST_ENV, INT21H
	mov ax, far_bss		;mov ax, @fardata? for MASM 5.x
	mov es, ax		;If not using .fardata? the segment override in mov di, ... can be eliminated!
%endif
	mov di, [es:string_tail]
	;mov [di], 0xB1 ;Symbol char
	;inc di
	call flush_buffer
	mov [es:string_tail], di
	ret


;string_tail is the "next free" location
%ifidni HOST_ENV, INT21H
segment far_bss private align=16 'FAR_BSS'
string_tail: resw 1h
string_buffer: resb (bufsiz + 1)
	
%else
segment bss_seg public align=16 'FAR_BSS'
string_tail: resw 1h
string_buffer: resb (bufsiz + 1)
%endif

