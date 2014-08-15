.8086
ifdef __STRDOS__
	.model small, nearstack
else
	.model small
endif

include MACROS.INC

;Exported vars
public str_token, get_command_line

;Constants
max_delim_length equ 07Fh

;Local macros:
;These macros provided by deathshadow at: 
;http://www.vintage-computer.com/vcforum/showthread.php?41240-A-library-of-string-subroutines-critique&p=314527#post314527
;Should only be run when ds:si is pointing at delimiter string
;
LOAD_INPUT_STRING macro
	mov   si, cx
	mov   bp, ds
	xchg  bp, dx
	mov   ds, bp
endm

;Should only be run when ds:si is pointing at input string

LOAD_DELIMITER_STRING macro
	mov   bp, ds
	xchg  bp, dx
	mov   ds, bp
	mov   cx, si
	mov   si, bx
	mov   ah, al
endm

.code

;struct

;Limitations- this function will not handle inter-segment strings (i.e. no
;huge pointer support... yet).
;char * __far __cdecl str_token(char * __far str, char * __far delim, char * __far outbuf);
;Returns a ptr to AFTER the first trailing delimiter

;Based on implementation here:
;http://www.cutcodedown.com/for_others/cr1901/strToken.txt
;Fewer macros because the version of MASM compatibility of assemblers I have on
;my test machines are inconsistent (and this is deliberate- maximum portability ;)...).

;This strtok may be useable as a strsep by checking the return value... possible
;future expansion.
;http://stackoverflow.com/questions/2377760/strtok-and-empty-fields
str_token proc near
	;__cdecl stack
	outbuf_fp equ dword ptr ss:[0Ch + bp]
	delim_fp equ dword ptr ss:[8 + bp]
	instr_seg equ word ptr ss:[6 + bp]
	instr_offset equ word ptr ss:[4 + bp]

	
	;Locals
	;delim_length equ word ptr ss:[bp - 2]
	;orig_instr_off equ word ptr ss:[bp - 4]
	;orig_delim_off equ word ptr ss:[bp - 6]
	;start_token_offset equ word ptr ss:[bp - 8]
	
	;Prologue/push registers
	push bp
	mov bp, sp
	sub sp, 8
	push cx
	push bx
	push si
	push di
	push ds
	push es
	push bp
	
	;When two values are listed, they are swapped using XCHG or MOV

	;DS : input segment, delimiter segment
	;SI : input offset, delimiter offset
	;DX : delimiter segment, input segment
	;CX : input offset (copy)
	;BX : delimiter offset
	;AH : input character (copy)
	;AL : input character, delimiter character
	;BP : Pushed frame pointer, scratch register for xchg
	
	lds bx, delim_fp
	les di, outbuf_fp
	mov dx, instr_seg
	mov cx, instr_offset

;ldchar = Leading Delimiter CHARacter
next_ldchar:	
	LOAD_INPUT_STRING
	LODSB_JZ zero_length_str ;Check for a leading null terminator... if so, there
				;is nothing to do!
	LOAD_DELIMITER_STRING ;mov current char to ah, and load delimiter segment
				;load first char in delimiter string to al.
				
	;LODSB_JZ next_char ;If the delimiter list is empty, don't bother
				;checking for leading delims!
				;TODO- figure out what C89 says about this
				;edge-case where the delimiter string is empty.
				;Commented out for now.
				
loop_check_next_ldchar:
	;LODSB_JZ next_ldchar ;We reached the end of delimiters or there is no
				;match to leading delimiter
	lodsb
	cmp ah, al
	je next_ldchar ;Check the next character if leading delimiter found.
	or al, al ;Check if we are at the end of the delimiter string.
	jne loop_check_next_ldchar ;If there are no leading delimiters left, there
			;was no match, and we fall through to the next section.
	
	
	;push cx
;next_char:
;	LOAD_INPUT_STRING
;	LODSB_JZ end_of_str
;	LOAD_DELIMITER_STRING
;	
;loop_compare_non_copy:
;	LODSB_JZ_JNE_AH next_char, loop_compare_non_copy ;Jump if AL is zero (no delimiter match) to next_char
							;Loop if AL is not equal to AH
							;Fall through if AL equals AH (delim found)
							
	dec cx	;When we checked for leading delimiters, the first non-match
		;caused the input string to point past the start of the relevant
		;token- correct for this by decrementing the offset copy to be
		;loaded next.
next_char_copy:
	LOAD_INPUT_STRING
	LODSB_JZ end_of_str	;If we made it this far, and AL is 0, end of input string found!
	LOAD_DELIMITER_STRING
	
loop_compare_copy:
	LODSB_JZ_JNE_AH output_char, loop_compare_copy ;Jump if AL is zero (no delimiter match) to output_char
							;Loop if AL is not equal to AH
							;Fall through if AL equals AH (delim found)
							
	;Possible outcomes:
	;Delimiter was found! Now, store the input str's token into the 
	;output buffer! Append null terminator. Return pointer to the character
	;AFTER the trailing delimiter. This permits us to change delimiters mid-string
	;or use a C-compatible str_token and keep going with the same delimiter.						
delim_found:
	xor   al, al ;Append null terminator to output string
	stosb
	; DX already == inputStringSeg
	mov  ax, cx
	pop bp ;Get the frame pointer back
	jmp cleanup
	
	;Possible outcomes to get to this point (all equivalent):
	;Null terminator was first character.
	;Null terminator followed a chain of 0 or more leading delimiters.
	;The string has been parsed to the null terminator on a PREVIOUS call.
	;Return pointer to the null terminator in this case. Which is in fact
	;the same pointer as the input!
zero_length_str:
	;LOAD_INPUT_STRING
	;lds si, dword ptr outbuf_offset
	xor al, al
	stosb
	;mov byte ptr es:[di], 0 ;Save a byte/time with no segment override :P..
	pop bp ;We need the old BP back
	mov dx, instr_seg
	mov ax, instr_offset
	;push bp 
	jmp cleanup
	
	;Possible outcomes:
	;Null terminator was found before a trailing delimiter- in this case,
	;the remaining characters become the token. Append null terminator.
	;Return pointer to the null terminator.
end_of_str:
	xor al, al
	stosb
	;mov byte ptr es:[di], 0
	;LOAD_INPUT_STRING
	;Input string is guaranteed to be loaded if we made it here.
	;DS has segment, SI has offset of next character (one beyond null terminator)
	pop bp ;We need the old BP back
	mov dx, ds
	mov ax, si
	dec ax ;We need to point to the old terminator.
	;jmp cleanup
	




	;les di, dword ptr outbuf_fp
	;
	;mov cx, si ;SI points to null terminator or delimiter
	;mov ax, si
	;sub cx, start_token_offset ;SI-start_token_offset is number of chars to xfer...
	;sub ax, instr_offset ;SI-instr_offset is the number of chars that were parsed
	;			;from the intsr in this call of strtok.
	;mov si, start_token_offset
	;
	;shr cx,1         ;adjust for words
	;rep movsw        ;copy words
	;adc cx,cx        ;cx=0 if even, cx=1 if odd
	;rep movsb        ;copies nothing if cx=0; copies 1 byte if cx=1
	;
	;mov byte ptr es:[di], 0 ;Transfer null terminator as well.
	;jmp cleanup

cleanup:
	;pop bp
	pop es
	pop ds
	pop di
	pop si
	pop bx
	pop cx
	mov sp, bp
	pop bp
	ret
	
output_char:
	mov  al, ah
	stosb
	jmp   next_char_copy		
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
	;assume bx:ptr byte	;For my convenience
	
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
	mov byte ptr es:[di], 0 ;Add a null terminator
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
