[list -]
%ifndef MACROS_ASM
%define MACROS_ASM 

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


;Macros to create a stack frame
%macro prolog 0.nolist
	%ifidni CPU_TARGET, 8086
		push bp
		mov bp, sp
	%else
		enter 0, 0
	%endif
%endmacro


;Macros to preserve registers
;Consider using strcat and pushing the save regs list, and popping it in multipop?
%macro  multipush 1-*.nolist
	%rep  %0 
		push    %1 
		%rotate 1 
	%endrep 
%endmacro

%macro  multipop 1-*.nolist 
  	%rep %0 
  		%rotate -1 
        	pop     %1 
        %endrep 
%endmacro


;Macros to define locals and arguments (c_decl)
;First specify near or far call
;Pass in arguments from left-to-right. %defines will be created right-to-left
;(ascending stack depth- args near top of stack defined first, b/c the correct
;offsets for future params depend on the size of previous params).
;
;NASM's stacksize appears to not consider a pushed BP for large (although
;it does for others), and does not support near procedures.
;See http://www.nasm.us/doc/nasmdoc4.html#section-4.8.1 and preproc.c, case PP_ARG
%macro defargs 1-*.nolist
	;%if (((%0 % 2) == 0) || (%0 == 1))
	;	%error 'Expected an even number of parameters (3 or more).'
	;%endif
	
	;We can make these macros more general later... i.e. 386 and above
	%ifidni %1, far
		%assign bp_offset 6
		%assign num_params ((%0 - 1) / 2)
	%elifidni %1, near
		%assign bp_offset 4
		%assign num_params ((%0 - 1) / 2) 
	%else
		%warning 'First parameter did not specify function call type. Assuming near.'
		%assign bp_offset 4
		%assign num_params (%0 / 2)
	%endif
	
	%rotate 1
	%rep num_params
		%xdefine %1 (bp_offset + bp)
		%assign bp_offset bp_offset + %2
		%rotate 2
	%endrep
	
	%undef bp_offset
%endmacro

%macro deflocals 1-*.nolist
	%if ((%0 % 2) || (%0 == 0))
		%error 'Expected an even number of parameters (2 or more).'
	%endif
	
	%assign bp_offset -2
	%rep (%0 / 2)
		%xdefine %1 (bp_offset + bp)
		%assign bp_offset bp_offset - %2
		%rotate 2
	%endrep
	
	%undef bp_offset
%endmacro


;Macros for dealing with pointer fun
%macro mkfptr 1.nolist
	dw %1, seg %1
%endmacro

;Push far pointers
%macro pushfp 1.nolist
	pushfp seg %1, %1
%endmacro

%macro pushfp 2.nolist
	mov dx, %1
	push dx
	mov ax, %2
	push ax
%endmacro

;Macros for dealing with stack manipulation
;Allows any addressing mode compatible with mov AX...
%macro pushparamb 1.nolist
	;%ifnum %1
	;	%ifidni CPU_TARGET, 8086
	;		mov ax, %1
	;		push ax
	;	%else
	;		push %1
	;	%endif
	;%endif
	xor ah, ah
	mov al, %1
	push ax
%endmacro

;Treat doublewords as two word pushes (for now)
%macro pushparamw 1.nolist
	;%ifnum %1
	;	%ifidni CPU_TARGET, 8086
	;		mov ax, %1
	;		push ax
	;	%else
	;		push %1
	;	%endif
	;%endif
	mov ax, %1
	push ax
%endmacro


;Useful if-else macro from NASM Manual.
%macro if 1.nolist 
	%push if 
	j%-1  %$ifnot 
%endmacro 

%macro else 0.nolist 
	%ifctx if 
		%repl   else 
		jmp     %$ifend 
		%$ifnot: 
	%else
		%error  "expected `if' before `else'" 
	%endif
%endmacro 

%macro endif 0.nolist 
	%ifctx if 
		%$ifnot: 
		%pop 
	%elifctx else 
		%$ifend: 
		%pop 
        %else 
        	%error  "expected `if' or `else' before `endif'" 
        %endif 
%endmacro

%macro print_msg 1.nolist
	%ifidni API, MSDOS_API
		mov ax, 900h
		mov dx, %1
		int 21h
	%endif
%endmacro

;%macro syscall
;
;%endmacro

;Test code from: http://www.nasm.us/doc/nasmdoc4.html#section-4.8.1
;    %push     mycontext        ; save the current context 
;    %stacksize flat           ;Vary this and run: nasm -E -Iinclude/ -DCPU_TARGET=8086 control\mouse.asm
;    %arg      i:word, j_ptr:word
;    %assign %$localsize 0       ; see text for explanation 
;    %local    k:word 
;
;        mov     ax,[i] 
;        mov     bx,[j_ptr]
;        mov	cx,[k]
;        add     ax,[bx] 
;        ret 
;
;    %pop                       ; restore original context


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

%macro LODSB_JE 1 ;destZ
	lodsb
	or   al, ah
	je   %1
%endmacro

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

%endif
[list +]
