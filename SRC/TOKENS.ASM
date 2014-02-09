.8086
ifdef __DOS__
	.model small, nearstack
else
	.model small
endif

public str_token, get_command_line

max_delim_length equ 07Fh


.code

;struct

;Limitations- this function will not handle inter-segment strings (i.e. no
;huge pointer support... yet).
;uint16_t __cdecl str_token(char * __far str, char * __far delim, char * __far outbuf);
str_token proc near
	;__cdecl stack
	outbuf_seg equ word ptr ss:[0Eh + bp]
	outbuf_offset equ word ptr ss:[0Ch + bp]
	delim_seg equ word ptr ss:[0Ah + bp]
	delim_offset equ word ptr ss:[8 + bp]
	instr_seg equ word ptr ss:[6 + bp]
	instr_offset equ word ptr ss:[4 + bp]

	
	;Locals
	delim_length equ word ptr ss:[bp - 2]
	orig_instr_off equ word ptr ss:[bp - 4]
	orig_delim_off equ word ptr ss:[bp - 6]
	start_token_offset equ word ptr ss:[bp - 8]
	
	;Prologue/push registers
	push bp
	mov bp, sp
	sub sp, 8
	push bx
	push si
	push di
	push ds
	push es
	
	;mov ax, delim_seg
	;mov ds, ax
	;mov si, delim_offset
	
	;Prepare segment registers- Originally I wanted these reversed, but
	;SCASB doesn't permit segment override.
	mov ax, instr_seg
	mov ds, ax
	mov si, instr_offset
	
	mov ax, delim_seg
	mov es, ax
	mov di, delim_offset
	mov orig_delim_off, di ;Will need to be reset each loop and after finding
				;length of delim_str
	
				
	;First delim str length
	mov cx, max_delim_length
	mov delim_length, max_delim_length
	xor al, al ;Check for null terminator
	repnz scasb ;SCAn until delimeter found or max traversed.
	sub delim_length, cx ;And subtract the number of times looped.
	dec delim_length
	;jz bad_delim_str
	
	
	;Then, truncate leading delimiters
	dec si ;To reduce the number of jumps (prefetch queue flushes), increments are at beginning of loop.
next_ldchar:
	inc si
	mov di, orig_delim_off
	dec di ;To reduce the number of jumps (prefetch queue flushes), increments are at beginning of loop.
	mov cx, delim_length
next_ldelim:
	inc di
	mov al, es:[di]
	cmp ds:[si], al
	jz next_ldchar
	loop next_ldelim
	cmp byte ptr ds:[si], 0 ;Check if the current character is null terminator
	jz zero_length_str ;If null was found, store a null terminator in the output buffer
			;and return 0 length.
	
			
	;Next, scan the string until the next delimiter is found.		
	mov start_token_offset, si ;Save the start of the token and restore 
				;the delimiter's offset
	dec si ;To reduce the number of jumps, increments are at beginning of loop.
next_char:	
	inc si
	;This will not jump to end_of_str when zero_length_str was intended due
	;to preceding jump logic.
	cmp byte ptr ds:[si], 0 ;Check if current char is null- don't bother other processing
			;for char if null was found.
	jz end_of_str
	xor cx, cx		;Reset CX- stores token length
	mov di, orig_delim_off
	dec di ;To reduce the number of jumps, increments are at beginning of loop.
next_delim:
	inc di
	mov al, es:[di] 
	cmp ds:[si], al	;Compare the input string to the delimiter
	jz delim_found
	inc cx
	cmp cx, delim_length
	jl next_delim   ;Delim length actually includes null terminator. Hence not
			;JLE (For sub, DEST <= DEST - SRC)
	jmp next_char 	;Otherwise, move on to next character.
	
	
	;Possible outcomes to get to this point (all equivalent):
	;Null terminator was first character.
	;Null terminator followed a chain of 0 or more leading delimiters.
	;The string has been parsed to the null terminator on a PREVIOUS call.
zero_length_str:	
	mov ax, outbuf_seg
	mov ds, ax
	mov si, outbuf_offset
	mov byte ptr ds:[si], 0 ;Save a byte/time with no segment override :P..
	xor ax, ax
	jmp cleanup
	
	;Possible outcomes:
	;Null terminator was found before a trailing delimiter- in this case,
	;the remaining characters become the token. Append null terminator.
	
	;Delimiter was found! Now, store the input str's token into the 
	;output buffer! Append null terminator.
delim_found:	
end_of_str:
	mov ax, outbuf_seg
	mov es, ax
	mov di, outbuf_offset ;Prepare ES:DI
	
	mov cx, si ;SI points to null terminator or delimiter
	mov ax, si
	sub cx, start_token_offset ;SI-start_token_offset is number of chars to xfer...
	sub ax, instr_offset ;SI-instr_offset is the number of chars that were parsed
				;from the intsr in this call of strtok.
	mov si, start_token_offset

	;mov ax, cx ;Return number of bytes to increment input string offset
	rep movsb
	mov byte ptr es:[di], 0 ;Transfer null terminator as well.
	;jmp cleanup

cleanup:	
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
;char * __near __cdecl get_command_line(uint8_t *)
;Input: Address of __near pointer which points to the buffer where DOS command line
;is stored.
;Return: AL- Length of Command Line
;Preserves- All registers besides CX
get_command_line proc near
	;__cdecl stack
	length_near_ptr equ word ptr ss:[4 + bp]
	assume bx:ptr byte	;For my convenience
	
	push bp
	mov bp, sp
	push bx
	push ds
	push es
	
	mov ah, 51h
	int 21h ;Get PSP segment: BX holds segment on return
	mov ds, bx
	mov si, 81h ;Start of command-line
	mov ax, @data ;Alias for DGROUP
	mov es, ax 
	;assume es:@data ;Actually, this assume might not be necessary...
	mov di, offset command_tail
	mov bx, length_near_ptr
	mov cl, byte ptr ds:[80h] ;Length of command line is stored here
	mov byte ptr es:[bx], cl ;Return the command line length to the pointed-to char. Since
				;DS doesn't point to the correct place, segment override
				;is used.
	xor ch,ch		;Make sure only CL is nonzero
	rep movsb
	mov ax, offset command_tail
	pop es
	pop ds
	pop bx
	
	mov sp, bp
	pop bp
	ret
get_command_line endp

.data?
command_tail db 129 dup(?)	;Why are contents retained between invocations?

;.data
;command_tail db 128 dup(0)
;ct_end: ;Errors out for some reason
ct_end label byte

end
