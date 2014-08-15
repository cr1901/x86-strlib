.8086
ifdef __STRDOS__
	.model small, nearstack
else
	.model small
endif

public print_str_unbuffered, print_value_b, print_value_w

.code
;Do not use this module yet- not ready!


;Inputs:
;BH- Page Number
;BL- Foreground Color
;DS:SI- String to print
;Returns: 
;Registers are preserved (or should be, barring bug in INT 0x10).
;There are times we cannot assume a data area exists. Use this function instead
;at those times.

;This function has not been updated for DOS usage yet.
print_str_unbuffered proc near
	push ax
	push cx
	push bp ;BP can be destroyed due to bug when scrolling.
	push si
	mov cx, 1
	mov ah, 0Eh ;Teletype Output
next_char_u:
	cmp byte ptr [si], 0
	;jmp end_str
	jz end_str_u
	mov al, [si]
	int 10h
	inc si
	jmp next_char_u
end_str_u:
	pop si
	pop bp
	pop cx
	pop ax
	ret
print_str_unbuffered endp


;print_value_b_unbuffered?
;Prints a byte value already converted from hex to ASCII.
;Inputs: AX- Value to print.
;BX- Page No/Foreground Color
;Registers are preserved.
print_value_b proc near
	push cx
	push bp
	mov cx, ax ;Preserve ax
	mov al, ah
	mov ah, 0Eh
	int 10h
	mov al, cl
	int 10h
	mov ah, ch
	pop bp
	pop cx
	ret
print_value_b endp


;print_value_w_unbuffered?
;Prints a word value already converted from hex to ASCII.
;Inputs: DX:AX- Value to print.
;BX- Page No/Foreground Color
;Registers are preserved.
print_value_w proc near
	push cx
	push bp
	mov cx, ax
	mov al, dh
	mov ah, 0Eh
	int 10h
	mov al, dl
	int 10h
	mov al, ch
	int 10h
	mov al, cl
	int 10h
	mov ax, cx
	pop bp
	pop cx
	ret
print_value_w endp
end
