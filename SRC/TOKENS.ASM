cpu CPU_TARGET

%include "MACROS.ASM"

group dgroup str_bss

;Exported vars
global str_token, get_command_line

;Constants
max_delim_length equ 07Fh

;Local macros:
;These macros provided by deathshadow at: 
;http://www.vintage-computer.com/vcforum/showthread.php?41240-A-library-of-string-subroutines-critique&p=314527#post314527
;Should only be run when ds:si is pointing at delimiter string
;
;Assumes: DX:CX=>input, DS=>delim segment
;Output: DS:SI=>input DX=>delim segment
%macro LOAD_INPUT_STRING 0
	mov   si, cx
	mov   bp, ds
	xchg  bp, dx
	mov   ds, bp
%endmacro

;Should only be run when ds:si is pointing at input string
;Assumes: DS:SI=>input, DX:BX=>delim, AL=>curr input
;Output: DX:CX=>input, DS:SI=>delim, AH=>curr input
%macro LOAD_DELIMITER_STRING 0
	mov   bp, ds
	xchg  bp, dx
	mov   ds, bp
	mov   cx, si
	mov   si, bx
	mov   ah, al
%endmacro

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
str_token:
	;__cdecl stack
	defargs far, instr_offset, 2, instr_seg, 2, delim_fp, 4, outbuf_fp, 4
	
	;Prologue/push registers
	prolog
	multipush cx, bx, si, di, ds, es, bp
	
	lds bx, [delim_fp]
	les di, [outbuf_fp]
	mov dx, [instr_seg]
	mov cx, [instr_offset]
	;When two values are listed, they are swapped using XCHG or MOV
	;DS : input segment, delimiter segment
	;SI : input offset, delimiter offset
	;DX : delimiter segment, input segment
	
	;CX : input offset (copy)
	;BX : delimiter offset (copy)
	;AH : input character (copy)
	;AL : input character, delimiter character
	;BP : Pushed frame pointer, scratch register for xchg
	
	;State: ES:DI=>outbuf DS:BX=>delim DX:CX=>input
;ldchar = Leading Delimiter CHARacter
next_ldchar:	
	LOAD_INPUT_STRING
	lodsb
	or al, al
	jz zero_length_str ;Check for a leading null terminator... if so, there 
		;is nothing to do!
	LOAD_DELIMITER_STRING ;mov current char to ah, and load delimiter segment
				;load first char in delimiter string to al.			
	;LODSB_JZ next_char ;If the delimiter list is empty, don't bother
	;checking for leading delims! TODO- figure out what C89 says about this
	;edge-case where the delimiter string is empty. Commented out for now.
	
loop_check_next_ldchar:
	lodsb
	cmp al, ah ;Does input char match current delimiter?
	je next_ldchar ;Check the next character if leading delimiter found.
	or al, al ;Check if we are at the end of the delimiter string.
	jnz loop_check_next_ldchar ;If there are no leading delimiters left, there
			;was no match, and we fall through to the next section.
			
	dec cx	;When we checked for leading delimiters, the first non-match
		;caused the input string to point past the start of the relevant
		;token- correct for this by decrementing the offset copy to be
		;loaded next.	
next_char_copy:
	LOAD_INPUT_STRING
	lodsb
	or al, al
	jz end_of_str	;If we made it this far, and AL is 0, end of input string found!
	LOAD_DELIMITER_STRING
	
loop_compare_copy:
	lodsb ;Load delimiter into al
	or al, al
	if z ;If delimiter string is at the end, send char to output buffer, and
		;grab a new character from input.
		mov  al, ah
		stosb
		jmp next_char_copy
	endif
	
	cmp al, ah ;Does the input string (ah) equal the current delimiter (al)?
	jne loop_compare_copy ;If so, fall through. If not, check another delim.
							
	;Possible outcomes:
	;Delimiter was found! Now, store the input str's token into the 
	;output buffer! Append null terminator. Return pointer to the character
	;AFTER the trailing delimiter. This permits us to change delimiters mid-string
	;or use a C-compatible str_token and keep going with the same delimiter.						
delim_found:
	mov ax, cx ;DX already == inputStringSeg- CX points one past last found		
	;delimiter in input string.
cleanup:
	mov byte [es:di], 0 ;Append a null terminator
	multipop cx, bx, si, di, ds, es, bp
	epilog
	retf
	
	;Possible outcomes to get to this point (all equivalent):
	;Null terminator was first character.
	;Null terminator followed a chain of 0 or more leading delimiters.
	;The string has been parsed to the null terminator on a PREVIOUS call.
	;Return pointer to the input string to indicate nothing was consumed/nothing
	;to do.
zero_length_str:	
	pop bp ;We need the frame pointer back.
	mov dx, [instr_seg] ;DX already == inputStringSeg
	mov ax, [instr_offset]
	push bp ;Now we don't need it, but cleanup: expects it to be on stack!
	jmp cleanup
	
	
	;Possible outcomes:
	;Null terminator was found before a trailing delimiter- in this case,
	;the remaining characters become the token. Append null terminator.
	;Return pointer to the null terminator.
end_of_str: ;Input string is guaranteed to be loaded if we made it here.
	;DS has segment, SI has offset of next character (one beyond null terminator)
	mov dx, ds
	mov ax, si
	dec ax ;We need to point to the null terminator- not one beyond.
	jmp cleanup


;Stores a copy of the DOS command line in a near buffer (inside DGROUP).
;Do not use in ROMable mode (for now)!
;char * __near __cdecl get_command_line(uint8_t *)
;Input: Address of __near pointer which points to the buffer where DOS command line
;is stored.
;Return: AL- Length of Command Line
;Preserves- All registers besides CX
get_command_line:
	;__cdecl stack
	defargs near, length_near_ptr, 2
	;assume bx:ptr byte	;For my convenience
	
	prolog
	multipush bx, ds, es
	
	mov ah, 51h
	int 21h ;Get PSP segment: BX holds segment on return
	mov ds, bx
	mov si, 81h ;Start of command-line
	mov ax, seg command_tail
	mov es, ax
	mov di, command_tail
	mov bx, [length_near_ptr]
	mov cl, [ds:80h] ;Length of command line is stored here
	mov [es:bx], cl ;Return the command line length to the pointed-to char. Since
				;DS doesn't point to the correct place, segment override
				;is used.
	xor ch,ch		;Make sure only CL is nonzero
	rep movsb
	mov byte [es:di], 0 ;Add a null terminator
	mov ax, command_tail
	
	multipop bx, ds, es
	epilog
	ret

segment str_bss private align=16 'STR_BSS'
command_tail: resb 129h	;Why are contents retained between invocations?
ct_end: resb 1h
