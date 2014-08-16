%macro prolog 1
	%ifidni CPU_TARGET, 8086
		push bp
		mov bp, sp
		%if %1 != 0
			sub sp, %1
		%endif
	%else
		enter %1, 0
	%endif
%endmacro

%macro epilog 0
	%ifidni CPU_TARGET, 8086
		mov sp, bp
		pop bp
	%else
		leave
	%endif
%endmacro

;Macro(s) for HEXASCII.ASM
%macro SWAP_ENDIANNESS_32B 0
	xchg dh, dl
	xchg ah, al
%endmacro

;Additional macro(s) for TOKENS.ASM
%macro LODSB_JZ_JE_AH 2 ;destZ,destE
	LODSB_JZ %1
	cmp   al, ah
	je   %2
%endmacro

;Below macros provided by deathshadow at VCF...
;Names changed for my preference
;http://www.vintage-computer.com/vcforum/showthread.php?41240-A-library-of-string-subroutines-critique&p=314527#post314527
;http://www.cutcodedown.com/for_others/cr1901/strToken.txt
; -------------------------- START macroS -----------------------------

; Common handy ones I use all the time, I'd probably put these
; in an include as they're REALLY useful

%macro LODSB_JZ 1 ;destZ
	lodsb
	or   al, al
	jz   %1
%endmacro


%macro LODSB_JZ_JNE_AH 2 ;destZ,destNE
	LODSB_JZ %1
	cmp   al, ah
	jne   %2
%endmacro 
;
;PUSH_MANY macro r1,r2,r3,r4,r5,r6,r7,r8,r9,r10
;	ifnb r1
;		push r1
;		PUSH_MANY r2,r3,r4,r5,r6,r7,r8,r9,r10
;	endif
;endm
;
;POP_MANY macro r1,r2,r3,r4,r5,r6,r7,r8,r9,r10
;	; there's probably a more efficient way to write this...
;	; but it's a macro, who gives a ****
;	;
;	;For the sake of compatibility with other versions of MASM-compatible assemblers...
;	;MASM has VARARG, but I do not know which version first introduced this.
;	;I have only ever been able to find a manual for version 6.- W. Jones
;	;I can see myself screwing up with this function, btw... since order
;	;is NOT reversed from PUSH :).
;	ifnb r10
;		pop r10
;	endif
;	ifnb r9
;		pop r9
;	endif
;	ifnb r8
;		pop r8
;	endif
;	ifnb r7
;		pop r7
;	endif
;	ifnb r6
;		pop r6
;	endif
;	ifnb r5
;		pop r5
;	endif
;	ifnb r4
;		pop r4
;	endif
;	ifnb r3
;		pop r3
;	endif
;	ifnb r2
;		pop r2
;	endif
;	ifnb r1
;		pop r1
;	endif
;endm
;
;CFUNC_RESERVE macro varSize:req,r1,r2,r3,r4,r5,r6,r7,r8,r9
;	push  bp
;	mov   bp, sp
;	ifdif varSize,0
;		add   bp, varSize
;	endif
;	PUSH_MANY r1,r2,r3,r4,r5,r6,r7,r8,r9
;endm
;
;CFUNC_RESTORE macro r1,r2,r3,r4,r5,r6,r7,r8,r9
;	POP_MANY bp,r1,r2,r3,r4,r5,r6,r7,r8,r9
;endm
