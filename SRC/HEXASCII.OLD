.8086
ifdef __STRDOS__
	.model small, nearstack
else
	.model small
endif

include MACROS.INC

public hex_to_ascii, print_value_f ;, ascii_to_hex, hex_to_ubcd

;Future conventions:
;function_name- 16 bit, unsigned
;function_names- 16 bit, signed
;function_name32- 32 bit, unsigned
;function_name32s- 32 bit, signed


.code
;uint32_t __cdecl hex_to_ascii(uint16_t value)
;Inputs- 16-bit hex value (unsigned)
;Returns- DX- Two MSNibbles of value in ASCII (DH-ASCII Character that 
;corresponds to MSB, DL- second-most MSB)
;AX- Two LSNibbles of value in ASCII (AH-ASCII Character that corresponds to 
;second-most LSB, AL- LSB)
;Preserves- All registers besides CX
;
;Value is returned is stored in registers as a 32-bit value- akin to an
;implementation-defined C multicharacter constant. See:
;http://stackoverflow.com/questions/6944730/multiple-characters-in-a-character-constant
;
;Since C strings are byte-based, and stored by concatenation in memory, 
;the return value needs to be stored MSB-byte first (Since that's how integers 
;converted to strings are typically read/stored- MSB first :P).
;Since x86 is little endian, it is up to the user to either swap endianness beforehand,
;then store DX and then AX, or do byte-based stores starting from DH.
;
;Apply "let the user decide in application" principle :P- leaving the swap to
;the user can also save cycles :D. There should be use-cases for just keeping the
;value in registers as well.

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
	;xchg dh, dl ;Correct for endianness
	;xchg ah, al
	mov sp, bp
	pop bp
	;x86 is little endian... we want to print the value
	;from MSB to LSB.
	
	ret
hex_to_ascii endp


;void __cdecl print_value_f(uint32_t far_ptr, uint8_t __far * fp_buffer)
;Convert a far pointer to ASCII and print (print removed). Does NOT append
;null terminator. Apply "let the user decide in application" principle :P.
;Inputs: Far-pointer on the stack, little endian, far pointer to buffer
;Address of buffer to print to.
;Registers are preserved.
print_value_f proc near
	;__cdecl stack
	fpbuf equ dword ptr ss:[8 + bp]
	print_seg equ word ptr ss:[6 + bp]
	print_off equ word ptr ss:[4 + bp]

	push bp
	mov bp, sp
	push ax
	push dx
	push bx
	push si
	push ds
	
	lds si, fpbuf
	;mov ax, word ptr ss:[0Ah + bp] ;Get the segment of the ascii buffer
	;mov ds, ax
	;mov ax, word ptr ss:[8 + bp] ;Get the offset of the ascii buffer
	;mov si, ax
	
	mov ax, print_seg ;Get the segment to print first
	push ax
	call hex_to_ascii
	add sp, 2
	xor bx, bx
	SWAP_ENDIANNESS_32B
	;Use stosb/ES:DI?
	mov word ptr ds:[si], dx
	mov word ptr ds:[si + 2], ax
	
	mov al, 3Ah ;ASCII Colon
	mov byte ptr ds:[si + 4], al
	
	mov ax, word ptr print_off ;Then get the offset
	push ax
	call hex_to_ascii
	add sp, 2
	xor bx, bx
	SWAP_ENDIANNESS_32B
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


;uint32_t __cdecl ascii_to_hex(uint8_t __far * fp_buffer)
;Inputs- Far pointer to char buffer with strlen max 4. Will process characters
;to end of input, but correct results not guaranteed if strlen > 4. 
;Up to user to length check.
;Returns- AX- Equivalent 16-bit value
;Preserves- All registers besides CX, DX
;ascii_to_hex proc
;	ascii_ptr equ ss:[4 + bp]
;	
;	push bp
;	mov bp, sp
;	push bx
;	push ds
;	xor ax, ax
;	lds si, ascii_ptr
;	mov cx, 3
;	
;next_char_atoh:	
;	lodsb
;	or ax, ax
;	jz end_of_str
;	sub ax, 30h ;subtract ASCII bias
;	mov di, cx ;Store CX temporarily 
;	shl cl, 1
;	shl cl, 1 ;Multiply CL by 4
;	shl ax, cl ;Shift AX to the relevant nibble
;	add dx, ax ;Add value to that stored in DX
;	dec cl
;	js skip_reset_cl ;If sign flag is set, restore CL
;	mov cl, 3
;skip_reset_cl:
;	xor ah, ah
;	jmp next_char_atoh
;	
;end_of_str:
;	mov ax, dx
;	pop ds
;	pop bx
;	mov sp, bp
;	pop bp
;	ret
;ascii_to_hex endp
;
;
;hex_to_ubcd proc
;
;hex_to_ubcd endp

end
