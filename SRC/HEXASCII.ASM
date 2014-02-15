.8086
ifdef __DOS__
	.model small, nearstack
else
	.model small
endif


public hex_to_ascii, print_value_f


.code
;uint32_t __cdecl hex_to_ascii(uint16_t value)
;Inputs- 16-bit hex value (unsigned)
;Returns- DX- Two MSNibbles, AX- Two LSNibbles of value
;Preserves- All registers besides CX
hex_to_ascii proc near
	;Improvement: Caller passes a pointer as parameter using C-calling
	;convention. What's the easiest way to get far pointer on the stack?
	;push ds, push si?
	;Probably not such an improvement after all due to need to manipulate
	;return values.
	
	hex_value equ word ptr ss:[4 + bp]
	temp_ascii equ ss:[-4 + bp]
	
	push bp
	mov bp, sp
	sub sp, 4 ;We need temporary space for each hex byte.
	push si
	
	mov ax, hex_value ;Skip the BP, IP get the input value
	
	mov cx, 4
	xor si, si
	mov dx, ax ;Save it temporarily
	
next_digit:
	;Somehow these 5 lines of code work to convert hex to ASCII...
	;Apparently from to 4004 days...
	and al,0fh
	add al,90h
	daa    
	adc al,40h
	daa
	
	mov temp_ascii[si], al ;Save the value
	mov ax, dx ;Shift to the next nibble
	push cx ;push cl?
	mov cl, 4
	shr ax, cl
	;shr ax, 1 ;Inside loop: ax, cl form can't be used.
	;shr ax, 1
	;shr ax, 1
	;shr ax, 1
	mov dx, ax ;Save the value again
	pop cx ;pop cl?
	inc si
	loop next_digit
	
	pop si ;Preserve SI
	pop ax ;Low two digits of ASCII (points to temp_ascii)
	pop dx ;High two digits of ASCII (temp_ascii + 0x02)
	xchg dh, dl ;Correct for endianness
	xchg ah, al
	mov sp, bp
	pop bp
	;x86 is little endian... we want to print the value
	;from MSB to LSB.
	
	ret
hex_to_ascii endp


;void __cdecl print_value_f(uint32_t far_ptr, uint8_t __far * fp_buffer)
;Convert a far pointer to ASCII and print.
;Inputs: Far-pointer on the stack, little endian, far pointer to buffer
;Address of buffer to print to.
;BX- Page No/Foreground Color
;Registers are preserved.
print_value_f proc near
	;__cdecl stack
	fpbuf_seg equ word ptr ss:[0Ah + bp]
	fpbuf_off equ word ptr ss:[8 + bp]
	print_seg equ word ptr ss:[6 + bp]
	print_off equ word ptr ss:[4 + bp]

	push bp
	mov bp, sp
	push ax
	push dx
	push bx
	push si
	push ds
	
	mov ax, word ptr ss:[0Ah + bp] ;Get the segment of the ascii buffer
	mov ds, ax
	mov ax, word ptr ss:[8 + bp] ;Get the offset of the ascii buffer
	mov si, ax
	
	mov ax, word ptr ss:[6 + bp] ;Get the segment to print first
	push ax
	call hex_to_ascii
	add sp, 2
	xor bx, bx
	mov word ptr ds:[si], dx
	mov word ptr ds:[si + 2], ax
	
	mov al, 3Ah ;ASCII Colon
	mov byte ptr ds:[si + 4], al
	
	mov ax, word ptr ss:[4 + bp] ;Then get the offset
	push ax
	call hex_to_ascii
	add sp, 2
	xor bx, bx
	mov word ptr ds:[si + 5], dx
	mov word ptr ds:[si + 7], ax
	
	
	pop ds
	pop si
	pop bx
	pop dx
	pop ax
	mov sp, bp
	pop bp
	ret
print_value_f endp
end
