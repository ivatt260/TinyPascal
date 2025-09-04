;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCode Interpreter for the TinyPascal PCode compiler.
;
; This PCode interpreter is written to run on the Intel 8080
; (and, thus, the Z-80) running CPM-2.2
;
; It runs the "V07" version of PCODE.
;
; currently:
;	- first version; runs slow!
;	- assumes "memory" is sandboxed, thus PEEK and POKE
;	  work in one segment of memory. (not physical
;	  address)
;	- SETS interpretation not fully working.
;
;	NOTE: this work started off as a TinyC program. 
;	PCode operators are being re-written; the speed-up
; 	is notable!
;
; JohnS; ivatt260@gmail.com
; September 4 2025
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ORG	100H

;       Run time start off for Small C.
        sphl            ; save the stack pointer
        shld    stksav
        lhld    6       ; pick up core top
        lxi     d,-10   ; decrease by 10 for safety
        dad     d
        sphl            ; set stack pointer

        call    stdioinit       ; initialize stdio

	lxi	h,0080H
	push	h
        lxi     h,0081H
        push    h
        call    Xarglist

        lhld    Xargc
        push    h
        ;lxi     h,Xargv
        lxi     h,0080H
        push    h
        call    main    ; call main program
        pop     d
        pop     d
        lhld    stksav ; restore stack pointer
        ret             ; go back to CCP
stksav ds      2


;*****************************************************
;                                                    *
;       runtime library for small C compiler         *
;                                                    *
;       c.s - runtime routine for basic C code       *
;                                                    *
;               Ron Cain                             *
;                                                    *
;*****************************************************
;
; fetch char from (HL) and sign extend into HL
ccgchar: mov     a,m
ccsxt:  mov     l,a
        rlc
        sbb     a
        mov     h,a
        ret
; fetch int from (HL)
ccgint: mov     a,m
        inx     h
        mov     h,m
        mov     l,a
        ret
; store char from HL into (DE)
ccpchar: mov     a,l
        stax    d
        ret
; store int from HL into (DE)
ccpint: mov     a,l
        stax    d
        inx     d
        mov     a,h
        stax    d
        ret
; "or" HL and DE into HL
ccor:   mov     a,l
        ora     e
        mov     l,a
        mov     a,h
        ora     d
        mov     h,a
        ret
; "xor" HL and DE into HL
ccxor:  mov     a,l
        xra     e
        mov     l,a
        mov     a,h
        xra     d
        mov     h,a
        ret
; "and" HL and DE into HL
ccand:  mov     a,l
        ana     e
        mov     l,a
        mov     a,h
        ana     d
        mov     h,a
        ret
;
;JAS;......logical operations: HL set to 0 (false) or 1 (true)
;JAS;
;JAS; DE equ HL
;JAScceq:   call    cccmp
;JAS        rz
;JAS        dcx     h
;JAS        ret
;JAS; DE ne HL
;JASccne:   call    cccmp
;JAS        rnz
;JAS        dcx     h
;JAS        ret

; DE gtr HL [signed]
ccgt:   xchg
        call    cccmp
        rc
        dcx     h
        ret
; DE leq HL [signed]
ccle:   call    cccmp
        rz
        rc
        dcx     h
        ret
; DE geq HL [signed]
ccge:   call    cccmp
        rnc
        dcx     h
        ret
; DE lt HL [signed]
cclt:   call    cccmp
        rc
        dcx     h
        ret
;JAS; DE >= HL [unsigned]
;JASccuge:  call    ccucmp
;JAS        rnc
;JAS        dcx     h
;JAS        ret
;JAS; DE < HL [unsigned]
;JASccult:  call    ccucmp
;JAS        rc
;JAS        dcx     h
;JAS        ret
;JAS; DE > HL [unsigned]
;JASccugt:  xchg
;JAS        call    ccucmp
;JAS        rc
;JAS        dcx     h
;JAS        ret
;JAS; DE <= HL [unsigned]
;JASccule:  call    ccucmp
;JAS        rz
;JAS        rc
;JAS        dcx     h
;JAS        ret
; signed compare of DE and HL
;   carry is sign of difference [set => DE < HL]
;   zero is zero/non-zero
cccmp:  mov     a,e
        sub     l
        mov     e,a
        mov     a,d
        sbb     h
        lxi     h,1             ;preset true
        jm      cccmp1
        ora     e               ;resets carry
        ret
cccmp1: ora     e
        stc
        ret
;JAS; unsigned compare of DE and HL
;JAS;   carry is sign of difference [set => DE < HL]
;JAS;   zero is zero/non-zero
;JASccucmp: mov     a,d
;JAS        cmp     h
;JAS        jnz     ccucmp1
;JAS        mov     a,e
;JAS        cmp     l
;JASccucmp1: lxi     h,1             ;preset true
;JAS        ret
; shift DE right logically by HL, move to HL
cclsr:  xchg
cclsr1: dcr     e
        rm
        stc
        cmc
        mov     a,h
        rar
        mov     h,a
        mov     a,l
        rar
        mov     l,a
        stc
        cmc
        jmp     cclsr1
; shift DE right arithmetically by HL, move to HL
ccasr:  xchg
ccasr1: dcr     e
        rm
        mov     a,h
        ral
        mov     a,h
        rar
        mov     h,a
        mov     a,l
        rar
        mov     l,a
        jmp     ccasr1
; shift DE left arithmetically by HL, move to HL
ccasl:  xchg
ccasl1: dcr     e
        rm
        dad     h
        jmp     ccasl1
; HL = DE - HL
ccsub:  mov     a,e
        sub     l
        mov     l,a
        mov     a,d
        sbb     h
        mov     h,a
        ret
; HL = -HL
ccneg:  call    cccom
        inx     h
        ret
; HL = ~HL
cccom:  mov     a,h
        cma
        mov     h,a
        mov     a,l
        cma
        mov     l,a
        ret
; HL = notHL
cclneg: mov     a,h
        ora     l
        jz      cclneg1
        lxi     h,0
        ret
cclneg1: inx     h
        ret
; HL = !!HL
ccbool: call    cclneg
        jmp     cclneg

; HL = DE / HL, DE = DE % HL
ccdiv:  mov     b,h
        mov     c,l
        mov     a,d
        xra     b
        push    psw
        mov     a,d
        ora     a
        cm      ccdeneg
        mov     a,b
        ora     a
        cm      ccbcneg
        mvi     a,16
        push    psw
        xchg
        lxi     d,0
ccdiv1: dad     h
        call    ccrdel
        jz      ccdiv2
        call    cccmpbd
        jm      ccdiv2
        mov     a,l
        ori     1
        mov     l,a
        mov     a,e
        sub     c
        mov     e,a
        mov     a,d
        sbb     b
        mov     d,a
ccdiv2: pop     psw
        dcr     a
        jz      ccdiv3
        push    psw
        jmp     ccdiv1
ccdiv3: pop     psw
        rp
        call    ccdeneg
        xchg
        call    ccdeneg
        xchg
        ret

; {DE = -DE}
ccdeneg:
        mov     a,d
        cma
        mov     d,a
        mov     a,e
        cma
        mov     e,a
        inx     d
        ret
; {BC = -BC}
ccbcneg:
        mov     a,b
        cma
        mov     b,a
        mov     a,c
        cma
        mov     c,a
        inx     b
        ret
; {DE <r<r 1}
ccrdel: mov     a,e
        ral
        mov     e,a
        mov     a,d
        ral
        mov     d,a
        ora     e
        ret
; {BC : DE}
cccmpbd:
        mov     a,e
        sub     c
        mov     a,d
        sbb     b
        ret
; case jump
cccase: xchg                    ;switch value to DE. exchange HL with DE
        pop     h               ;get table address
cccase1: call    cccase4          ;get case value
        mov     a,e
        cmp     c               ;equal to switch value cc
        jnz     cccase2          ;no
        mov     a,d
        cmp     b               ;equal to switch value cc
        jnz     cccase2          ;no
        call    cccase4          ;get case label
        jz      cccase3          ;end of table, go to default
        push    b
        ret                     ;case jump
cccase2: call    cccase4          ;get case label
        jnz     cccase1          ;next case
cccase3: dcx     h
        dcx     h
        dcx     h               ;position HL to the default label
        mov     d,m             ;read where it points to
        dcx     h
        mov     e,m
        xchg                    ;exchange HL with DE and vice versa - address is now in HL
        pchl                    ;default jump. loads HL to PC
cccase4: mov     c,m
        inx     h
        mov     b,m
        inx     h
        mov     a,c
        ora     b
        ret
;
;
;
Xstktop: lxi     h,0     ;return current stack pointer (for sbrk)
        dad     sp
        ret

; fetch char from (HL) into HL no sign extend
cguchar: mov     l,m
        mvi     h,0
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;JASisalpha:
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,97
;JAS	pop 	d
;JAS	call	ccge
;JAS	push	h
;JAS	lxi 	h,4
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,122
;JAS	pop 	d
;JAS	call	ccle
;JAS	pop 	d
;JAS	call	ccand
;JAS	push	h
;JAS	lxi 	h,4
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,65
;JAS	pop 	d
;JAS	call	ccge
;JAS	push	h
;JAS	lxi 	h,6
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,90
;JAS	pop 	d
;JAS	call	ccle
;JAS	pop 	d
;JAS	call	ccand
;JAS	pop 	d
;JAS	call	ccor
;JAS	mov 	a,h
;JAS	ora 	l
;JAS	jz  	CC2
;JAS	lxi 	h,1
;JAS	jmp 	CC1
;JAS	jmp 	CC3
;JASCC2:
;JAS	lxi 	h,0
;JAS	jmp 	CC1
;JASCC3:
;JASCC1:
;JAS	ret
;JASisupper:
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,65
;JAS	pop 	d
;JAS	call	ccge
;JAS	push	h
;JAS	lxi 	h,4
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,90
;JAS	pop 	d
;JAS	call	ccle
;JAS	pop 	d
;JAS	call	ccand
;JAS	mov 	a,h
;JAS	ora 	l
;JAS	jz  	CC5
;JAS	lxi 	h,1
;JAS	jmp 	CC4
;JAS	jmp 	CC6
;JASCC5:
;JAS	lxi 	h,0
;JAS	jmp 	CC4
;JASCC6:
;JASCC4:
;JAS	ret
;JASislower:
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,97
;JAS	pop 	d
;JAS	call	ccge
;JAS	push	h
;JAS	lxi 	h,4
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,122
;JAS	pop 	d
;JAS	call	ccle
;JAS	pop 	d
;JAS	call	ccand
;JAS	mov 	a,h
;JAS	ora 	l
;JAS	jz  	CC8
;JAS	lxi 	h,1
;JAS	jmp 	CC7
;JAS	jmp 	CC9
;JASCC8:
;JAS	lxi 	h,0
;JAS	jmp 	CC7
;JASCC9:
;JASCC7:
;JAS	ret
;JASisdigit:
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,48
;JAS	pop 	d
;JAS	call	ccge
;JAS	push	h
;JAS	lxi 	h,4
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,57
;JAS	pop 	d
;JAS	call	ccle
;JAS	pop 	d
;JAS	call	ccand
;JAS	mov 	a,h
;JAS	ora 	l
;JAS	jz  	CC11
;JAS	lxi 	h,1
;JAS	jmp 	CC10
;JAS	jmp 	CC12
;JASCC11:
;JAS	lxi 	h,0
;JAS	jmp 	CC10
;JASCC12:
;JASCC10:
;JAS	ret
;JAS
;JASisspace:
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,32
;JAS	pop 	d
;JAS	call	cceq
;JAS	push	h
;JAS	lxi 	h,4
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,9
;JAS	pop 	d
;JAS	call	cceq
;JAS	pop 	d
;JAS	call	ccor
;JAS	push	h
;JAS	lxi 	h,4
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,10
;JAS	pop 	d
;JAS	call	cceq
;JAS	pop 	d
;JAS	call	ccor
;JAS	mov 	a,h
;JAS	ora 	l
;JAS	jz  	CC14
;JAS	lxi 	h,1
;JAS	jmp 	CC13
;JAS	jmp 	CC15
;JASCC14:
;JAS	lxi 	h,0
;JAS	jmp 	CC13
;JASCC15:
;JASCC13:
;JAS	ret



toupper:
	lxi 	h,2
	dad 	sp
	call	ccgchar
	push	h
	lxi 	h,97
	pop 	d
	call	ccge
	mov 	a,h
	ora 	l
	jz  	CC17
	lxi 	h,2
	dad 	sp
	call	ccgchar
	push	h
	lxi 	h,122
	pop 	d
	call	ccle
CC17:
	call	ccbool
	mov 	a,h
	ora 	l
	jz  	CC18
	lxi 	h,2
	dad 	sp
	call	ccgchar
	push	h
	lxi 	h,32
	pop 	d
	call	ccsub
	jmp 	CC19
CC18:
	lxi 	h,2
	dad 	sp
	call	ccgchar
CC19:
	jmp 	CC16
CC16:
	ret

;JAStolower:
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,65
;JAS	pop 	d
;JAS	call	ccge
;JAS	mov 	a,h
;JAS	ora 	l
;JAS	jz  	CC21
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,90
;JAS	pop 	d
;JAS	call	ccle
;JASCC21:
;JAS	call	ccbool
;JAS	mov 	a,h
;JAS	ora 	l
;JAS	jz  	CC22
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JAS	push	h
;JAS	lxi 	h,32
;JAS	pop 	d
;JAS	dad 	d
;JAS	jmp 	CC23
;JASCC22:
;JAS	lxi 	h,2
;JAS	dad 	sp
;JAS	call	ccgchar
;JASCC23:
;JAS	jmp 	CC20
;JASCC20:
;JAS	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; BELOW HERE IS THE C compiler output.
;
; ensure c compiler format is correct:
; .,$s/\#//g
; g/\.nlist/d
; g/\.area/d
; .,$s/\.db/db/
; .,$s/\.dw/dw/
; .,$s/\$/LABEL/g
; .,$s/rca1802_mode/rcaMode/g
; convert strz to string, terminated with a NULL
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;

; size of PCode stORe, AND PEEK-POKE-memsize
MEMSIZE		EQU	8192 ; 01000H
PPMEMSIZE 	EQU	1024 ; 01000H- NOTe not sure if this is ever checked
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RCA1802MODE 
; - some items are pre-MULtiplied
;   to help the 1802 interpreter.
; - the assembled Modula/Pascal
;   file has absolute jmp AND cal
;   addresses baked in.

TRUE		EQU	0FFFFH
FALSE		EQU	NOT TRUE

R1802MODE 	EQU	TRUE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; MCODE instructions

	IF NOT R1802MODE
OPVER	EQU	0000H
OPLIT	EQU	0001H
OPLOD	EQU	0002H
OPSTO	EQU	0003H
OPOPR	EQU	0004H
BBOUND	EQU	0005H
OPSTK	EQU	0006H
OPINT	EQU	0007H
OPPCAL	EQU	0008H
OPFCAL	EQU	0009H
OPPRET	EQU	000AH
OPFRET	EQU	000BH
OPJMP	EQU	000CH
OPJPC	EQU	000DH
TXOUT	EQU	000EH
TXIN	EQU	000FH
OPXIT	EQU	0010H

;OPOPR operations

NEG$UINT16	EQU  0
PLUS$UINT16	EQU  1
MINUS$UINT16	EQU  2
MUL$UINT16	EQU  3
DIV$UINT16	EQU  4
MOD$UINT16	EQU  5
EQL$UINT16	EQU  6
NEQ$UINT16	EQU  7
LSS$UINT16	EQU  8
GEQ$UINT16	EQU  9
GTR$UINT16	EQU 10
LEQ$UINT16	EQU 11
AND$UINT16	EQU 12
OR$UINT16	EQU 13
NOT$UINT16	EQU 14
PEEK		EQU 15
POKE		EQU 16
OR$SET16	EQU 17
AND$SET16	EQU 18
DOTDOT$SET16	EQU 19
INVERT$SET16	EQU 20
INTTO$SET16	EQU 21
EQL$SET16	EQU 22
NEQ$SET16	EQU 23
INCL$SET16	EQU 24
FLIPTOS16	EQU 25

	ENDIF

	IF R1802MODE
OPVER	EQU	0000H SHL 0001H
OPLIT	EQU	0001H SHL 0001H
OPLOD	EQU	0002H SHL 0001H
OPSTO	EQU	0003H SHL 0001H
OPOPR	EQU	0004H SHL 0001H
BBOUND	EQU	0005H SHL 0001H
OPSTK	EQU	0006H SHL 0001H
OPINT	EQU	0007H SHL 0001H
OPPCAL	EQU	0008H SHL 0001H
OPFCAL	EQU	0009H SHL 0001H
OPPRET	EQU	000AH SHL 0001H
OPFRET	EQU	000BH SHL 0001H
OPJMP	EQU	000CH SHL 0001H
OPJPC	EQU	000DH SHL 0001H
TXOUT	EQU	000EH SHL 0001H
TXIN	EQU	000FH SHL 0001H
OPXIT	EQU	0010H SHL 0001H


NEG$UINT16	EQU  0 SHL 0002H
PLUS$UINT16	EQU  1 SHL 0002H
MINUS$UINT16	EQU  2 SHL 0002H
MUL$UINT16	EQU  3 SHL 0002H
DIV$UINT16	EQU  4 SHL 0002H
MOD$UINT16	EQU  5 SHL 0002H
EQL$UINT16	EQU  6 SHL 0002H
NEQ$UINT16	EQU  7 SHL 0002H
LSS$UINT16	EQU  8 SHL 0002H
GEQ$UINT16	EQU  9 SHL 0002H
GTR$UINT16	EQU 10 SHL 0002H
LEQ$UINT16	EQU 11 SHL 0002H
AND$UINT16	EQU 12 SHL 0002H
OR$UINT16	EQU 13 SHL 0002H
NOT$UINT16	EQU 14 SHL 0002H
PEEK		EQU 15 SHL 0002H
POKE		EQU 16 SHL 0002H
OR$SET16	EQU 17 SHL 0002H
AND$SET16	EQU 18 SHL 0002H
DOTDOT$SET16	EQU 19 SHL 0002H
INVERT$SET16	EQU 20 SHL 0002H
INTTO$SET16	EQU 21 SHL 0002H
EQL$SET16	EQU 22 SHL 0002H
NEQ$SET16	EQU 23 SHL 0002H
INCL$SET16	EQU 24 SHL 0002H
FLIPTOS16	EQU 25 SHL 0002H
	ENDIF
; HL = DE * HL [signed]
ccmul:  mov     b,h
        mov     c,l
        lxi     h,0
ccmul1: mov     a,c
        rrc
        jnc     ccmul2
        dad     d
ccmul2: xra     a
        mov     a,b
        rar
        mov     b,a
        mov     a,c
        rar
        mov     c,a
        ora     b
        rz
        xra     a
        mov     a,e
        ral
        mov     e,a
        mov     a,d
        ral
        mov     d,a
        ora     e
        rz
        jmp     ccmul1
; unsigned divide DE by HL and return quotient in HL, remainder in DE
; HL = DE / HL, DE = DE % HL
ccudiv: mov     b,h             ; store divisor to bc 
        mov     c,l
        lxi     h,0             ; clear remainder
        xra     a               ; clear carry        
        mvi     a,17            ; load loop counter
        push    psw
ccduv1: mov     a,e             ; left shift dividend into carry 
        ral
        mov     e,a
        mov     a,d
        ral
        mov     d,a
        jc      ccduv2          ; we have to keep carry -> calling else branch
        pop     psw             ; decrement loop counter
        dcr     a
        jz      ccduv5
        push    psw
        xra     a               ; clear carry
        jmp     ccduv3
ccduv2: pop     psw             ; decrement loop counter
        dcr     a
        jz      ccduv5
        push    psw
        stc                     ; set carry
ccduv3: mov     a,l             ; left shift carry into remainder 
        ral
        mov     l,a
        mov     a,h
        ral
        mov     h,a
        mov     a,l             ; substract divisor from remainder
        sub     c
        mov     l,a
        mov     a,h
        sbb     b
        mov     h,a
        jnc     ccduv4          ; if result negative, add back divisor, clear carry
        mov     a,l             ; add back divisor
        add     c
        mov     l,a
        mov     a,h
        adc     b
        mov     h,a     
        xra     a               ; clear carry
        jmp     ccduv1
ccduv4: stc                     ; set carry
        jmp     ccduv1
ccduv5: xchg
        ret
;
; compares. From the TinyC code.
;


; unsigned compare of DE and HL
;   carry is sign of difference [set => DE < HL]
;   zero is zero/non-zero
ccucmp: mov     a,d
        cmp     h
        jnz     ccucmp1
        mov     a,e
        cmp     l
ccucmp1: lxi     h,1             ;preset true
        ret

;......logical operations: HL set to 0 (false) or 1 (true)
;
; DE equ HL
cceq:   call    ccucmp
        rz
        dcx     h
        ret
; DE ne HL
ccne:   call    ccucmp
        rnz
        dcx     h
        ret


; DE >= HL [unsigned]
ccuge:  call    ccucmp
        rnc
        dcx     h
        ret
; DE < HL [unsigned]
ccult:  call    ccucmp
        rc
        dcx     h
        ret
; DE > HL [unsigned]
ccugt:  xchg
        call    ccucmp
        rc
        dcx     h
        ret
; DE <= HL [unsigned]
ccule:  call    ccucmp
        rz
        rc
        dcx     h
        ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OPOPR
;;;;;;;
INTERP$OPOPR:

; NOT HANDLED YET:
;OPR$NOT1802MODE:
;	lhld	progPtr
;	inx 	h
;	shld	progPtr
;	dcx 	h
;;;;;;;;;;;;;;;;;;;;;
; OPOPR before switch
;;;;;;;;;;;;;;;;;;;;;

	;OPR$DOTDOT$SET16:
	; - not implemented in compiler



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; now, before jumping to the opr to execute:
	; register "B" is not used.
	; register "C" is not used.
	; register "D" is high byte of pointer to current instruction in memory
	; register "E" is low  byte of pointer to current instruction in memory
	; register "H" is indeterminate
	; register "L" is instruction
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	inx	d	; skip past "OPOPR"
	xchg
	mov	a,m	; instruction in A
	xchg

	; advance INTERP program pointer
	; do this here, so we dont worry about it in individual
	; OPR instructions.
	lhld	progPtr
	inx	h
	inx	h
	shld	progPtr

	cpi NEG$UINT16   ! jz OPR$NEG$UINT16
	cpi PLUS$UINT16  ! jz STK$TTL1
	cpi MINUS$UINT16 ! jz STK$TTL1
	cpi MUL$UINT16   ! jz STK$TTL1
	cpi DIV$UINT16   ! jz STK$TTL1
	cpi MOD$UINT16   ! jz STK$TTL1
	cpi EQL$UINT16   ! jz STK$TTL1
	cpi NEQ$UINT16   ! jz STK$TTL1
	cpi LSS$UINT16   ! jz STK$TTL1
	cpi GEQ$UINT16   ! jz STK$TTL1
	cpi GTR$UINT16   ! jz STK$TTL1
	cpi LEQ$UINT16   ! jz STK$TTL1
	cpi AND$UINT16   ! jz STK$TTL1
	cpi OR$UINT16    ! jz STK$TTL1
	cpi NOT$UINT16   ! jz OPR$NOT$UINT16

	cpi PEEK         ! jz OPR$PEEK
	cpi POKE         ! jz OPR$POKE

	cpi OR$SET16     ! jz STK$TTL1
	cpi AND$SET16    ! jz STK$TTL1

	cpi DOTDOT$SET16 ! jz OPR$DOTDOT$SET16
	cpi INVERT$SET16 ! jz OPR$INVERT$SET16
	cpi INTTO$SET16  ! jz OPR$INTTO$SET16

	cpi EQL$SET16    ! jz STK$TTL1
	cpi NEQ$SET16    ! jz STK$TTL1

	cpi INCL$SET16   ! jz OPR$INCL$SET16
	cpi FLIPTOS16    ! jz OPR$FLIPTOS16

	jmp	OPR$UNKNOWN ; catastrophic error - OPR type not handled, fall off jz tree.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;OPR$INCL$SET16:
;    TOPS--;
;    tmp = s[TOPS];
;    s[TOPS] = s[TOPS] & s[TOPS+1];
;    s[TOPS] = s[TOPS] == tmp;


OPR$NOT$UINT16:
OPR$PEEK:
OPR$POKE:
OPR$FLIP$SET16:
OPR$INTTO$SET16:
OPR$INVERT$SET16:
OPR$FLIP$TOS16:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; stack flippers. 
	;
	; take TOS, do something with it, and save. Stack size
	; does NOT change for these OPR types.
	;
	; eg, peek(x); TOS changes to contents of memory(x)
	;
	;Lots of common code; ax is 
	; preserved until the operation must take place,
	; so share this code then do specifics at end.
	
	; (B,C), (H,L) can be used for "whatever" here.
	; (D,E) pointer to instruction string - the byte after
	; the "opopr" command. (i.e., the opopr instruction).
        ;    s[TOPS] = s[TOPS];
	
	; get TOPS we point to 16 bit words here.
	lhld	topOfStk
	mov	b,h	; copy current TOS to (B,C)
	mov	c,l

	; double it as we point to bytes. We have the
	; original TOS in (B,C), copy it to (H,L),
	; add it together (multiplying x2) and store
	; it in (D,E)
	mov	h,b
	mov	l,c
	dad	b
	mov	d,h
	mov	e,l

	; point to interpreter stk and add the current
	; tos in bytes.
	lxi	h,interpstk
	dad	d

	; so now, (h,l) points to top (next free element) of stack.
	; get the numbers back, and add/subtract....
	inx	h
	mov	b,m
	dcx	h
	mov	c,m
	dcx	h
	mov	d,m
	dcx	h
	mov	e,m
		

	; ok, TOPS and TOS set up for sending back a return value;
	; like xx = peek(100); has 100 on stack, return xx.
	; for other things, like POKE, that CONSUMES 2 stack
	; positions, we have to get not only the 2nd parameter off
	; stack, but also have to DECREMENT TOPS.

	;;;;;;;;;;;;;;;;;;;;
	;common code.
	;
	; we've popped 2 16 bit numbers off of the stack.
	;
	; first number (in BC) contains the number to work on
	; if there is 1 parameter, or, if there are 2 parameters, the 
	; OR the RHS of the equation
	;
	; (DE) contains the LHS of the equation, only if there
	; are 2 parameters. Otherwise, it's undefined.
	; eg:
	; peek(xx) = xx is in (BC)
	; poke(adr,xx) = xx is in (BC), adr in (DE)
	;
	; and  (H,L) contains locn where the results go, if there
	; are results, and we had 2 parameters...
	;;;;;;;;;;;;;;;;;;;;

	cpi NOT$UINT16   ! jz ONOTU16
	cpi PEEK         ! jz OPEEK
	cpi POKE         ! jz OPOKE
	cpi INVERT$SET16 ! jz INVS16
	cpi FLIPTOS16    ! jz FT16
	cpi INTTO$SET16  ! jz ITS16

	jmp	OPR$UNKNOWN	; should not get here

	;;;;;;;;;;;;;;;;;;;;
	; NOT for UINT16 - reverse false/true
	;
	; stack - do not increment/decrement, 
	; as we are just replacing what is 
	; at TOPS already.

ONOTU16:
	mov     a,b
        ora     c
        jz      RTRUE
	jmp	RFALSE

	;;;;;;;;;;;;;;;;;;;;
	; PEEK - take address on TOPS, use it to index
	; into peekPokeMemory, get the byte, and replace
	; TOPS with this.
	;
OPEEK:
	push	h	; save stack
	lxi	h,peekPokeMem	; get peek/poke memory "storage"
	dad	b	; add the offset (the peek location)

	mov	c,m	; get the peekPoke memory location byte
	
	pop	h	; get the stack back, and "skip" the
	inx	h	; 2nd parameter, put the peek value
	inx	h	; where the first parameter was

	mov	m,c	; push it to stack TOS
	inx	h
	mvi	m,0	; remember, its a byte...

	; topOfStk: 
	; as we replace the peek location with peek value, no
	; change required.
	jmp	INTERPL



	;;;;;;;;;;;;;;;;;;;;
	; POKE - take address on TOPS, use it to index
	; store byte in locn.
	; eg poke(address, value);
	; BC contains value (actually, only C as it's 8 bit)
	; HL used to get 2nd number off stack, thn
	; as pointer for poking;
	; TOPS has to be decremented by 2 places at the end.
OPOKE:

	lxi	h,peekPokeMem	; get peek/poke memory "storage"
	dad	d		; add the offset (the peek location)

	; HL now contains location of where to place byte.
	; Byte is in register "C" from RHS of equation
	; remember, it is a byte, so do NOT zero the upper
	; 16 bits or anything silly like that!

	mov	m,c

	; stack - hmmm, we have taken 2 UINT16s off the top, (address, data)
	; so ensure that this is correct.

	; decrement TOPS we point to 16 bit words here.
	; POKE CONSUMES 2 stack positions; 2 parameters and no return value
	lhld	topOfStk
	dcx	h	; decrement 1 position..
	dcx	h	; ... and the 2nd position.
	shld	topOfStk	; save TOPS--;

	jmp	INTERPL

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; flip the top two 16 bit numbers on stack.
	; we have these in (DE) and (BC), and have "popped"
	; them off the stack earlier, so "push" them on
	; and call it a day.
	
	;    tmp = s[TOPS];
	;    s[TOPS] = s[TOPS-1];
	;    s[TOPS-1] = tmp;

FT16:
	mov	m,c
	inx	h
	mov	m,b
	inx	h
	mov	m,e
	inx	h
	mov	m,d

	; flip consumes 0 STACK positions, just continue
	jmp	INTERPL

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; INVERT$SET16
	;           case opr_invert_set16:
	;          s[tops] = s[tops] ^ 0xFFFF;

	; invert (XOR) BC
INVS16:
	inx	h	; 2nd parameter, put the to-invert value
	inx	h	; is where the first parameter was

	mov	a,c	; push it to stack TOS
	xri	0FFH
	mov	m,a
	inx	h
	
	mov	a,b
	xri	0FFH
	mov	m,a

	; invert consumes 0 STACK positions, just continue
	jmp	INTERPL

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; INTTO$SET16
ITS16:
	; INTTO$SET16:
	; s[TOPS] = 1 << s[TOPS];
	;
	; shift 1 via what is in TOS.
	; (DE) - current TOS value - contains a count.
	; input of:
	;    0: rv := 1;
	;    1: rv := 2;
	;    2: rv := 4;
	;    3: rv := 8;
	;    4: rv := 16;
	;    5: rv := 32;
	;    6: rv := 64;


	xra	a	; clear carry.
	; (DE) contains the count
	; set up (BC) for result.
	mvi	c,1
	mvi	b,0

	mov	a,e	; we only use 4 lowest bits, 16 bits
	ani	0FH
	mov	e,a
ITS16LOOP:
	mov	a,e
	cmp	0
	jz	ITS16FIN

	; shift (BC) left
	mov	a,c
	ral
	mov	c,a
	mov	a,b
	rlc	
	mov	b,a


	; decrement counter
	dcx	d
	jmp	ITS16LOOP
ITS16FIN:

	inx	h	; 2nd parameter, put the peek value
	inx	h	; where the first parameter was
	mov	m,c
	inx	h
	mov	m,b
	; INTTOSET16 consumes 0 STACK positions, just continue
	jmp	INTERPL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OPR$DOTDOT$SET16: jmp OPR$UNKNOWN 	; compiler does not generate this (yet??)
OPR$INCL$SET16: jmp OPR$UNKNOWN		; not coded yet - should be.

; NEGate UINT16 - makes no sense, as we can't put a minus
; sign in front of it. Keep here for symmetry when we handle
; INT32s.
OPR$NEG$UINT16: jmp OPR$UNKNOWN		; can not negate unsigned, here as a place keeper.

OPR$UNKNOWN:
	
	; UNKNOWN operator, or operator not supported yet.
	lxi 	h,STR$UNKOPR
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
	jmp	INTERPL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stack consumers. Lots of common code; ax is 
; preserved until the operation must take place,
; so share this code then do specifics at end.
	
; (B,C), (H,L) can be used for "whatever" here.
; (D,E) pointer to instruction string - the byte after
; the "opopr" command. (i.e., the opopr instruction).
;    tops--;
;    s[tops] = s[tops] + s[tops+1];
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
STK$TTL1:

;OPR$PLUS$UINT16:
;OPR$MINUS$UINT16:
;OPR$MUL$UINT16;
;OPR$DIV$UINT16;
;OPR$MOD$UINT16;
;OPR$EQL$UINT16;
;OPR$NEQ$UINT16:
;OPR$LSS$UINT16:
;OPR$LEQ$UINT16:
;OPR$GEQ$UINT16:
;OPR$GTR$UINT16:
;OPR$AND$UINT16:
;OPR$OR$UINT16:
;OPR$OR$SET16:
;OPR$AND$SET16:

	; decrement TOPS we point to 16 bit words here.
	lhld	topOfStk
	mov	b,h	; copy current TOS to (B,C)
	mov	c,l

	dcx	h
	shld	topOfStk	; save tops--;


	; double it as we point to bytes. We have the
	; original TOS in (B,C), copy it to (H,L),
	; add it together (multiplying x2) and store
	; it in (D,E)
	mov	h,b
	mov	l,c
	dad	b
	mov	d,h
	mov	e,l

	; point to interpreter stk and add the current
	; tos in bytes.
	lxi	h,interpstk
	dad	d

	; so now, (h,l) points to top (next free element) of stack.
	; get the numbers back, and add/subtract....
	inx	h
	mov	b,m
	dcx	h
	mov	c,m
	dcx	h
	mov	d,m
	dcx	h
	mov	e,m

	;;;;;;;;;;;;;;;;;;;;
	;common code.
	;
	; Now, (B,C) contains the RHS of equation
	; and  (D,E) contains the LHS of equation
	; and  (H,L) contains locn where the results go
	;;;;;;;;;;;;;;;;;;;;

	; now remember which operation we were doing, and do it.

	cpi PLUS$UINT16  ! jz OPLSU16
	cpi MINUS$UINT16 ! jz OMINU16
	cpi MUL$UINT16   ! jz OMULU16
	cpi DIV$UINT16   ! jz ODIVU16
	cpi MOD$UINT16   ! jz OMODU16
	cpi EQL$UINT16   ! jz OEQLU16
	cpi NEQ$UINT16   ! jz ONEQU16
	cpi LSS$UINT16   ! jz OLSSU16
	cpi LEQ$UINT16   ! jz OLEQU16
	cpi GEQ$UINT16   ! jz OGEQU16
	cpi GTR$UINT16   ! jz OGTRU16
	cpi AND$UINT16   ! jz OANDU16
	cpi OR$UINT16    ! jz OORU16
	cpi OR$SET16     ! jz OORU16
	cpi AND$SET16    ! jz OANDU16
	cpi EQL$SET16    ! jz OEQLU16
	cpi NEQ$SET16    ! jz ONEQU16
	

	; hmmm should not be here
	jmp OPR$UNKNOWN ; stack consumers error; should not be here... 

OPLSU16:
	;;;;;;;;;;;;;;;;
	; do the ADD$UINT16 here
	xchg
	dad	b
	xchg

	; we have the pointer to s[tops-1]
	; from the pop 2 and add op above
	; so now store it.
	mov	m,e
	inx	h
	mov	m,d
	jmp	INTERPL

OMINU16:
	;;;;;;;;;;;;;;;;
	; do the MINUS$UINT16 here

	push	h	; (H,L) free now
	
	; do two's complement math; 
	; ones complement AX in (B,C)
	; (B,C) contains RHS of the equation...
	mov	a,b
	xri	0ffH
	mov	b,a
	mov	a,c
	xri	0FFH
	mov	c,a

	; two's complement of AX, in HL
	
	mvi	h,0
	mvi	l,1
	dad	b
	; ok, 2s complement done.
	; now do the subtract
	dad	d
	xchg		; now, "(D,E)" should contain result

	; get back the locn of where results go and save it
	pop	h

	; common style finish for these ops:
	mov	m,e
	inx	h
	mov 	m,d
	jmp	INTERPL
	
OMULU16:
	;;;;;;;;;;;;;;;;;;;;;;;;
	; do the DIV$UINT16 here
	; the SmallC divide routine says:
	; HL = DE * HL [signed]
	; there is no "unsigned multiply"
	;;;;;;;;;;;
	; ok:
	; (D,E) = LHS - that is ok.
	; (B,C) = RHS - move this to (H,L)
	push	h	; save locn for the results
	mov	h,b
	mov	l,c
	call	ccmul
	; move the results
	mov	d,h
	mov	e,l
	pop	h

	; common style finish for these ops:
	; we have the pointer to s[tops-1]
	; from the pop 2 and add op above
	; so now store it.
	mov	m,e
	inx	h
	mov	m,d
	jmp	INTERPL
	
ODIVU16:
	;;;;;;;;;;;;;;;;;;;;;;;;
	; do the DIV$UINT16 here
	; the SmallC divide routine says:
	; unsigned divide DE by HL and return quotient in HL, remainder in DE
	; HL = DE / HL, DE = DE % HL
	;;;;;;;;;;;;;;;;
	; ok:
	; (D,E) = LHS - that is ok.
	; (B,C) = RHS - move this to (H,L)
	push	h	; save locn for the results
	mov	h,b
	mov	l,c
	call	ccudiv
	; move the results
	mov	d,h
	mov	e,l
	pop	h

	; common style finish for these ops:
	; we have the pointer to s[tops-1]
	; from the pop 2 and add op above
	; so now store it.
	mov	m,e
	inx	h
	mov	m,d
	jmp	INTERPL

OMODU16:
	;;;;;;;;;;;;;;;;;;;;;;;;
	; do the MOD$UINT16 here
	; the SmallC divide routine says:
	; unsigned divide DE by HL and return quotient in HL, remainder in DE
	; HL = DE / HL, DE = DE % HL
	;;;;;;;;;;;;;;;;
	; ok:
	; (D,E) = LHS - that is ok.
	; (B,C) = RHS - move this to (H,L)
	push	h	; save locn for the results
	mov	h,b
	mov	l,c
	call	ccudiv
	; MOD - results already in (D,E)
	; so pop-n-store
	pop	h

	; common style finish for these ops:
	; we have the pointer to s[tops-1]
	; from the pop 2 and add op above
	; so now store it.
	mov	m,e
	inx	h
	mov	m,d
	jmp	INTERPL

	;;;;;;;;;;;;;;;;;;;;;;;;
	; do the EQL$UINT16 here
	; ok:
OEQLU16:
	; (D,E) = LHS - that is ok.
	; (B,C) = RHS - move this to (H,L)
	push	h	; save locn for the results
	mov	h,b
	mov	l,c
		
	; now we have (DE) comparing to (HL)
	; call compare, returns 0 or 1
	call	ccucmp

	pop	h
	jz	RTRUE
	jmp	RFALSE

RTRUE:
	mvi	m,1
	inx	h
	mvi	m,0
	jmp	INTERPL
RFALSE:	
	mvi	m,0
	inx	h
	mvi	m,0
	jmp	INTERPL

; DE ne HL
ONEQU16:
	push	h
	mov	h,b
	mov	l,c
	call	ccucmp
	pop	h
	jnz	RTRUE
	jmp	RFALSE
; DE < HL [unsigned]
OLSSU16:
	push	h
	mov	h,b
	mov	l,c
	call	ccucmp
	pop	h
	jc	RTRUE
	jmp	RFALSE
; DE <= HL [unsigned]
OLEQU16:
	push	h
	mov	h,b
	mov	l,c
	call    ccucmp
	pop	h
        jz	RTRUE
        Jc	RTRUE
	jmp	RFALSE
; DE >= HL [unsigned]
OGEQU16:
	push	h
	mov	h,b
	mov	l,c
	call    ccucmp
	pop	h
        Jnc	RTRUE
	jmp	RFALSE

; DE > HL [unsigned]
OGTRU16:
	push	h
	mov	h,b
	mov	l,c
	xchg
	call    ccucmp
	pop	h
        jc	RTRUE
	jmp	RFALSE

; AND - and HL and BC into HL
OANDU16:
	mov	a,d
	ana	b
	mov	d,a
	mov	a,e
	ana	c
	mov	e,a

	mov	m,e
	inx	h
	mov	m,d
	jmp	INTERPL

; or - or HL and BC into HL
OORU16:
	mov	a,d
	ora	b
	mov	d,a
	mov	a,e
	ora	c
	mov	e,a

	mov	m,e
	inx	h
	mov	m,d
	jmp	INTERPL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; interpret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
interpret:
; set tops to zero
	lxi 	h,0
	shld	topOfStk
; set dynamicink to zero
;	lxi 	h,0
	shld	dynamicLink
; set progptr to zero
;	lxi 	h,0
	shld	progPtr
;
; start of for loop, reading and executing PCode instructions;
;
INTERPL:
;
; about to get instruction and test rca1802 mode
;
;;;;;;;;;;;;;;;;;
;
	; notes included;
	; Register pairs:
	; 
	; rp PSW (accum and flag)
	; rp B   Registers B and C
	; rp D   Registers D and E
	; rp M   Registers H and L

	; get the instruction from memory+progPtr
	; "load register pair immediate a 16 bit value"
	; Reg (H,L) contains location of "memory[0]"
	lxi 	h,memory

	; store "MEMORY" memory location in (D,E)
	mov 	d,h
	mov	e,l

	; "load the register pair H and L direct"
	; The contents of the memory address are loaded into
	; register pair (H,L)
	lhld	progPtr

	; get start of memory into (D,E);
	; pop 	d

	; add register pair (D,E) to (H,L)
	dad 	d


	; (HL) points to the current instruction in memory.
	; save this current instruction pointer to (D,E)
	mov 	d,h
	mov	e,l

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; get the contents of memory byte into register L
	mov 	l,m
	
	; store contents of register pair (H,L) Direct
	; so the instruction byte is stored in MEM loc "instr"
	shld	instr
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; now, before jumping to the instruction to execute:
	; register "B" is not used.
	; register "C" is not used.
	; register "D" is high byte of pointer to current instruction in memory
	; register "E" is low  byte of pointer to current instruction in memory
	; register "H" is indeterminate
	; register "L" is instruction
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; jmp to the instruction to be executed.
	;
	; instructions are ordered in terms of mumber of calls
	; in "biggerMaze.mod", so that highest used instructions
	; are found early
	;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	mov	a,l

	; priority #1 - OPLIT
	; re-coded Aug 2025
	cpi	OPLIT
	jz	INTERP$OPLIT

	; priority #2 - OPLOD
	cpi	OPLOD
	jz	INTERP$OPLOD

	; priority #3 - OPSTK
	cpi	OPSTK
	jz	INTERP$OPSTK

	; priority #4 - OPOPR
	cpi	OPOPR
	jz	INTERP$OPOPR

	; priority $5 - OPSTO
	cpi	OPSTO
	jz	INTERP$OPSTO

	; priority #6 - TXOUT
	cpi	TXOUT
	jz	INTERP$TXOUT

	; priority #7 - OPPCAL
	cpi	OPPCAL
	jz	INTERP$OPPCAL

	; priority #8 - OPJPC
	cpi	OPJPC
	jz	INTERP$OPJPC

	; priority #9 - OPJMP
	cpi	OPJMP
	jz	INTERP$OPJMP

	; prioriry #10 - OPFCAL
	cpi	OPFCAL
	jz	INTERP$OPFCAL

	; priority #11 - OPINT
	cpi	OPINT
	jz	INTERP$OPINT

	; priority #12 - OPPRET
	cpi	OPPRET
	jz	INTERP$OPPRET

	; priority #13 - OPFRET
	cpi	OPFRET
	jz	INTERP$OPFRET

	; priority #14 - TXIN
	cpi	TXIN
	jz	INTERP$TXIN

	; priority #15 - OPVER
	cpi	OPVER
	jz	INTERP$OPVER

	; priority #16 - OPXIT
	cpi	OPXIT
	jz	INTERP$OPXIT

	; prioriry #17 - BBOUND
	cpi	BBOUND
	jz	INTERP$BBOUND

	; if here, instruction was not valid
	jmp	INTERP$INVINS

;;;;;;;
; OPVER
;;;;;;;

;;;;;;;
;      //printf ("version %c%c\n",memory[progPtr+1],memory[progPtr+2]);
;      puts("version:");
;      putc(memory[progPtr+1],stdout);
;      putc(memory[progPtr+2],stdout);
;      putc(0x0a,stdout);
;      if ((memory[progPtr+1] <>char zero) || (memory[progPtr+2] <> char seven)) {
;        puts ("EXPECTED VERSION 07 for this version of readhex");
;        exit(1);
;      }
;
;      progPtr += 3;
;;;;;;;



INTERP$OPVER:
	lxi 	h,STR$VERS
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,48
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jnz 	LABEL192
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,55
	pop 	d
	call	ccne
LABEL192:
	call	ccbool
	mov 	a,h
	ora 	l
	jz  	OPVER$FIN
	lxi 	h,STR$BADVER		;LABEL0+45
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
OPVER$FIN:
; increment progPtr by 3
	lhld	progPtr
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	shld	progPtr
	jmp	INTERPL

;;;;;;;
; OPLIT
;;;;;;;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; now, before jumping to the instruction to execute:
	; register "B" is not used.
	; register "C" is not used.
	; register "D" is high byte of pointer to current instruction in memory
	; register "E" is low  byte of pointer to current instruction in memory
	; register "H" is zero
	; register "L" is instruction
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;ax = memory(progtr+1, progtr+2)
	;tops ++
	;s[tops] = ax;
	;prgptr+=3;

INTERP$OPLIT:
;	Get the literal value from memory into h,l
	xchg
	inx	H	; increment pointer to current instruction in memory
	mov 	c,m	
	inx	H
	mov	b,m	; (B,C) contains the literal value in the instruction
			; stream

	; (B,C) has the literal
	; (D,E) nothing
	; (H,L) points to the last byte of the literal
	
	; incr tops - interpreter works in 16 bits, 8080 in 8 bits...
	lhld	topOfStk
	inx 	h	; we address 16 bit "words"
	mov	d,h
	mov	e,l
	shld	topOfStk

	; tops incremented, "16 bit" value of "tops" in (D,E) and (H,L)
	; add them together to do a "point to 8 bit" pointer
	dad	d

	;  so we have index x2, pointing to 16 bit words; copy this value in (D,E)
	mov	d,h
	mov	e,l

	; get the "byte" index in (D,E) and add it to the stack base 	
	lxi 	h,interpstk
	dad	d
	
	; so now we have a byte pointer, so store 2 bytes (our 16 bit "word") to stack
	; (H,L) now points to stack[tops], store literal 16 bit value to it.
	mov	m,b
	inx	H
	mov	m,c

	; add 3 to the progPtr here
	lhld	progPtr
	inx	h
	inx	h
	inx	h
	shld	progPtr

	jmp 	INTERPL

;;;;;;;
; OPLOD
;;;;;;;
INTERP$OPLOD:
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	shld	topOfStk
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	shld	lv
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	shld	ax
	lhld	rca1802mode
	mov 	a,h
	ora 	l
	jz  	OPLOD197
	lhld	ax
	push	h
	lxi 	h,1
	pop 	d
	call	cclsr
	shld	ax
OPLOD197:
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,interpstk
	push	h
	lhld	lv
	push	h
	mvi 	a,1
	call	base
	pop 	b
	push	h
	lhld	ax
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	ccpint
	lhld	progPtr
	push	h
	lxi 	h,4
	pop 	d
	dad 	d
	shld	progPtr
	jmp 	INTERPL

;;;;;;;
; OPSTO
;;;;;;;
INTERP$OPSTO:
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	shld	lv
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	shld	ax
	lhld	rca1802mode
	mov 	a,h
	ora 	l
	jz  	OPSTO200
	lhld	ax
	push	h
	lxi 	h,1
	pop 	d
	call	cclsr
	shld	ax
OPSTO200:
	lxi 	h,interpstk
	push	h
	lhld	lv
	push	h
	mvi 	a,1
	call	base
	pop 	b
	push	h
	lhld	ax
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	ccpint
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	shld	topOfStk
	lhld	progPtr
	push	h
	lxi 	h,4
	pop 	d
	dad 	d
	shld	progPtr
	jmp	INTERPL


;;;;;;;
; BBOUND
;;;;;;;
INTERP$BBOUND:
	lxi 	h,STR$BBND		;LABEL0+114
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
	jmp	INTERPL
;;;;;;;
; OPSTK
;;;;;;;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; now, before jumping to the instruction to execute:
	; register "B" is not used.
	; register "C" is not used.
	; register "D" is high byte of pointer to current instruction in memory
	; register "E" is low  byte of pointer to current instruction in memory
	; register "H" is zero
	; register "L" is instruction
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


INTERP$OPSTK:

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; OPSTK:
	;	8080-ified Aug 16 2025
	;	
	;	- could be cleaned up(shortened) a bit more.
	;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;      lv = memory[progPtr+1];
	;      ax = (memory[progPtr+2]*256)+memory[progPtr+3];
	;      // for the 1802 at least, it is shl'd to reduce runtime time
	;      if (rca1802_mode) ax = ax>>1;
	;
	;      if (lv == 0) {  // decrement
	;        tops = tops - ax;
	;       } else  { // increment
	;        tops = tops + ax;
	;      }
	;      progPtr += 4;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Get the literal value from memory into d,h,l
	;      lv = memory[progPtr+1];
	; 	switch (H,L) and (D,E)
	xchg
	inx	H	; point to memory[progPtr+1]
	mov 	e,m	; put the "lv direction flag" into (D,E) 
	mvi	d,0
	xchg		; now "lv direction flag" is in (H,L)
	shld	lv


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;      ax = (memory[progPtr+2]*256)+memory[progPtr+3];
	xchg
	inx	H	; increment pointer to current instruction in memory
	mov 	d,m	
	inx	H
	mov	e,m	; (D,E) contains "ax"
	xchg
	shld	ax

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; WORK ON THIS
	;      if (rca1802_mode) ax = ax>>1;
	lhld	rca1802mode
        mov     a,l
        ora     l
	jz	INTERP$OPSTK$AXOK

	; good website: https://chilliant.com/z80shift.html
	; and https://retroprogramming.it/2021/02/8080-z80-instruction-set/
	; RLC
	; RRC
	; RAL
	; RAR
	; AND A, OR A, XOR A all clear carry, XOR also zeroes.

	lhld	ax
	; ok, doing shift of ax.

	; clear carry bit
	ora	a
	; rotate high byte
	mov	a,h
	rar	
	mov	h,a
	; rotate, with the carry bit shifted in
	mov	a,l
	rrc	
	mov	l,a

	; store ax again, shifted to the right.
	shld	ax

INTERP$OPSTK$AXOK
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; do stack increment/decrement.
	;
	; get increment value and store it in (D,E)
	lhld	ax
	mov	d,h
	mov	e,l

	;      if (lv == 0) {  // decrement
	;        tops = tops - ax;
	;       } else  { // increment
	;        tops = tops + ax;
	;      }

	; get lv 
	; we increment if lv = 0001
	lhld	lv
	mov 	a,l
        ora     l
        jz      INTERP$OPSTK$DECREMENT

	;;;;;;;;;;;;;;;;;;;;;
	; we are incrementing
	lhld	topOfStk
	dad	D	; (D,E) is AX
	shld	topOfStk
	jmp	opstk$iosjp

INTERP$OPSTK$DECREMENT
	;;;;;;;;;;;;;;;;;;;;;
	; we are decrementing
	; do two's complement math; 

	; ones complement AX in (D,E)
	mov	a,d
	xri	0ffH
	mov	d,a
	mov	a,e
	xri	0FFH
	mov	e,a

	; two's complement of AX, in HL
	mvi	h,0
	mvi	l,1
	dad	d
	xchg		; now (D,E) contains the 2's complement of AX

	; get TOPS in (H,L), and add it to the Two's complement of AX
	lhld	topOfStk
	dad	d
	shld	topOfStk
OPSTK$IOSJP

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; add 4 to the progPtr here
	lhld	progPtr
	inx	h
	inx	h
	inx	h
	inx	h
	shld	progPtr

	jmp 	INTERPL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;
; OPINT
;;;;;;;
INTERP$OPINT:
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	shld	ax
	lhld	rca1802mode
	mov 	a,h
	ora 	l
	jz  	LABEL245
	lhld	ax
	push	h
	lxi 	h,1
	pop 	d
	call	cclsr
	shld	ax
LABEL245:
	lhld	topOfStk
	push	h
	lhld	ax
	pop 	d
	dad 	d
	shld	topOfStk
	lhld	progPtr
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	shld	progPtr
	jmp	INTERPL

;;;;;;;;;;;;;;;
; OPPCAL OPFCAL
;;;;;;;;;;;;;;;
INTERP$OPPCAL:
INTERP$OPFCAL:
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	shld	lv
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	push	h
	lhld	lv
	push	h
	mvi 	a,1
	call	base
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	push	h
	lhld	dynamicLink
	pop 	d
	call	ccpint
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	push	h
	lhld	progPtr
	push	h
	lxi 	h,4
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	shld	dynamicLink
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	shld	ax
	lhld	ax
	push	h
	lhld	startingOffset
	pop 	d
	call	ccsub
	shld	ax
	lhld	ax
	shld	progPtr
	jmp	INTERPL

;;;;;;;;
; OPPRET
;;;;;;;;
INTERP$OPPRET:
	lhld	dynamicLink
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	shld	topOfStk
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	shld	progPtr
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	shld	dynamicLink
	jmp	INTERPL

;;;;;;;;
; OPFRET
;;;;;;;;
INTERP$OPFRET:
	lxi 	h,interpstk
	push	h
	lhld	dynamicLink
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	shld	rv
	lhld	dynamicLink
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	shld	topOfStk
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	shld	progPtr
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	shld	dynamicLink
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	shld	topOfStk
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	dad 	h
	pop 	d
	dad 	d
	push	h
	lhld	rv
	pop 	d
	call	ccpint
	jmp	INTERPL

;;;;;;;
; OPJMP
;;;;;;;

;      ax = (memory[progPtr+1]*256)+memory[progPtr+2];
;      ax = ax-startingOffset;
;      progPtr = ax;
;
;;;;;;;


;;;;;;;
; OPJMP
;;;;;;;
	; register "B" is not used.
	; register "C" is not used.
	; register "D" is high byte of pointer to current instruction in memory
	; register "E" is low  byte of pointer to current instruction in memory
	; register "H" is zero
	; register "L" is instruction
INTERP$OPJMP
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	shld	ax
	lhld	ax
	push	h
	lhld	startingOffset
	pop 	d
	call	ccsub
	shld	ax
	lhld	ax
	shld	progPtr
	jmp	INTERPL




;INTERP$OPJMPTRY:
;	; get progPtr contents to get jmp address.
;	lhld	progPtr
;
;	inx	h	; progPtr +1
;	mov	d,m	; (D) = memoryprogPtr+1]
;	inx	h	;
;	mov	e,m	; ....*256+memory[progPtr+2]
;			; (D,E) = ax;
;	
;	lhld	startingOffset
;	mov	b,m	; 
;	inx	h
;	mov	c,m	;(B,C) = startingOffset
;	;
;	mov	h,d	; subtract only the upper 8 bits,
;	sub	b	; as startingOffset will be byte aligned
;	mov	d,b	; (D,E) = ax - startingOffset
;	
;	; progPtr = ax;
;	lhld	progPtr
;	mov	m,d	
;	inx	h
;	mov	m,e
;
;	jmp	INTERPL

;	
;
;IFDEF OLDCODE
;	lxi 	h,memory
;	push	h
;	lhld	progPtr
;	push	h
;	lxi 	h,1
;	pop 	d
;	dad 	d
;	pop 	d
;	dad 	d
;	mov 	l,m
;	mvi 	h,0
;	push	h
;	lxi 	h,256
;	pop 	d
;	call	ccmul
;	push	h
;	lxi 	h,memory
;	push	h
;	lhld	progPtr
;	push	h
;	lxi 	h,2
;	pop 	d
;	dad 	d
;	pop 	d
;	dad 	d
;	mov 	l,m
;	mvi 	h,0
;	pop 	d
;	dad 	d
;	shld	ax
;	lhld	ax
;	push	h
;	lhld	startingOffset
;	pop 	d
;	call	ccsub
;	shld	ax
;	lhld	ax
;	shld	progPtr
;ENDIF
;	jmp	INTERPL

;;;;;;;
; OPJPC
;;;;;;;
INTERP$OPJPC:
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	shld	topOfStk
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL257
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	shld	ax
	lhld	ax
	push	h
	lhld	startingOffset
	pop 	d
	call	ccsub
	shld	ax
	lhld	ax
	shld	progPtr
	jmp 	LABEL258
LABEL257:
	lhld	progPtr
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	shld	progPtr
LABEL258:
	jmp	INTERPL


;;;;;;;
; OPXIT
;;;;;;;
INTERP$OPXIT:
	lxi 	h,STR$NORMAL	; LABEL0+165
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
	jmp 	INTERPF

;;;;;;;;
; invalid instruction
;;;;;;;;
INTERP$INVINS:
	lxi 	h,STR$INVINS	; LABEL0+196
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	INTERPF

;;;;;;;;;;;;;;;;;;;;
; FIN INTERPRET LOOP
;;;;;;;;;;;;;;;;;;;;
INTERPF:
	ret
;;;;;;;;
;; TXOUT
;;;;;;;;
;    } else if (TXOUT == instr) {
;      lv = memory[progPtr+1];
;      ax = (memory[progPtr+2]*256)+memory[progPtr+3];
;      ax = ax - startingOffset;
;      progPtr = progPtr+4;
;
;      if (lv == IO_charString) {
;        // too many carriage returns puts(&memory[ax]);
;         while (memory[ax] > '\0') {
;          putc (memory[ax],stdout);
;          ax = ax + 1;
;        }
;
;      } else if (lv == IO_uint16) {
;        itoa (s[tops],nbuf);
;        ax = 0;
;        while (nbuf[ax] > '\0') {
;          putc (nbuf[ax],stdout);
;          ax = ax + 1;
;        }
;        tops = tops -1;
;
;      } else if (lv == IO_char) {
;        putc (s[tops],stdout);
;        tops = tops -1;
;
;      } else {
;        //printf ("interpret, unknown type %d\n",lv);
;        puts("interpret, unknown type");
;        exit(1);
;      }
;
;
;
;
INTERP$TXOUT:
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	shld	lv
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,memory
	push	h
	lhld	progPtr
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	shld	ax
	lhld	ax
	push	h
	lhld	startingOffset
	pop 	d
	call	ccsub
	shld	ax
	lhld	progPtr
	push	h
	lxi 	h,4
	pop 	d
	dad 	d
	shld	progPtr
	lhld	lv
	push	h
	lxi 	h,1
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	TXO261
TXO262:
	lxi 	h,memory
	push	h
	lhld	ax
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,0
	pop 	d
	call	ccugt
	mov 	a,h
	ora 	l
	jz  	TXO263
	lxi 	h,memory
	push	h
	lhld	ax
	pop 	d
	dad 	d
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,1
	push	h
	mvi 	a,2
	call	fputc
	pop 	b
	pop 	b
	lhld	ax
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	shld	ax
	jmp 	TXO262
TXO263:
	jmp 	INTERPL
TXO261:
	lhld	lv
	push	h
	lxi 	h,2
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	TXO265
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,nbuf
	push	h
	mvi 	a,2
	call	itoa
	pop 	b
	pop 	b
	lxi 	h,0
	shld	ax
TX0266:
	lxi 	h,nbuf
	push	h
	lhld	ax
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	lxi 	h,0
	pop 	d
	call	ccgt
	mov 	a,h
	ora 	l
	jz  	TXO267
	lxi 	h,nbuf
	push	h
	lhld	ax
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lhld	ax
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	shld	ax
	jmp 	TX0266
TXO267:
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	shld	topOfStk
	jmp 	INTERPL
TXO265:
	lhld	lv
	push	h
	lxi 	h,3
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	TXO269
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	shld	topofStk
	jmp 	INTERPL
TXO269:
	lxi 	h,STR$UNKTYP	;LABEL0+141
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
	jmp	INTERPL

;;;;;;;
; TXIN
;;;;;;;
INTERP$TXIN:
	lhld	topOfStk
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	shld	topOfStk
	lxi 	h,interpstk
	push	h
	lhld	topOfStk
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,0
	push	h
	mvi 	a,1
	call	fgetc
	pop 	b
	pop 	d
	call	ccpint
	lhld	progPtr
	inx 	h
	shld	progPtr
	dcx 	h
	jmp	INTERPL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Xarglist:
	dcx 	sp
	push	b
	lxi 	h,0
	shld	Xargc
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	dad 	d
	call	ccgchar
	shld	Xargc
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL2:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,127
	pop 	d
	call	cclt
	mov 	a,h
	ora 	l
	jnz 	LABEL4
	jmp 	LABEL5
LABEL3:
	lxi 	h,0
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	jmp 	LABEL2
LABEL4:
	lxi 	h,dataLine
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	call	ccgchar
	pop 	d
	mov 	a,l
	stax	d
	jmp 	LABEL3
LABEL5:
LABEL1:
	inx 	sp
	pop 	b
	ret
bdos1:
	lxi 	h,255
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	pop 	d
	call	ccand
	jmp 	LABEL6
LABEL6:
	ret
bdos:
;       CP/M support routine
;       bdos(C,DE);
;       char *DE; int C;
;       returns H=B,L=A per CPM standard
        pop     h       ; hold return address
        pop     d       ; get bdos function number
        pop     b       ; get DE register argument
        push    d
        push    b
        push    h
        call    5
        mov     h,b
        mov     l,a
LABEL7:
	ret
exit:
        jmp     0
LABEL8:
	ret
fgetc:
	push	b
LABEL10:
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	Xfgetc
	pop 	b
	pop 	d
	call	ccpint
	push	h
	lxi 	h,13
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL11
	jmp 	LABEL10
LABEL11:
	lxi 	h,0
	dad 	sp
	call	ccgint
	jmp 	LABEL9
LABEL9:
	pop 	b
	ret
Xfgetc:
	push	b
	push	b
	push	b
	push	b
	lxi 	h,10
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	push	h
	lda	eofstdin
	call	ccsxt
	call	cclneg
	pop 	d
	call	ccand
	mov 	a,h
	ora 	l
	jz  	LABEL13
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,1
	push	h
	lxi 	h,0
	push	h
	mvi 	a,2
	call	bdos1
	pop 	b
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,4
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL14
	lxi 	h,1
	mov 	a,l
	sta 	eofstdin
	lxi 	h,1
	call	ccneg
	jmp 	LABEL12
	jmp 	LABEL15
LABEL14:
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL16
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
	jmp 	LABEL17
LABEL16:
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,13
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL18
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,10
	pop 	d
	call	ccpint
	lxi 	h,2
	push	h
	lxi 	h,10
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
LABEL18:
	lxi 	h,4
	dad 	sp
	call	ccgint
	jmp 	LABEL12
LABEL17:
LABEL15:
LABEL13:
	lxi 	h,modes
	push	h
	lxi 	h,12
	dad 	sp
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL19
	lxi 	h,bptr
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,eptr
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	ccuge
	mov 	a,h
	ora 	l
	jz  	LABEL20
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	buffaddr 	; in XFgetc
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,eptr
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	buffaddr	; in XFgetc
	pop 	b
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL21
LABEL22:
	lxi 	h,26
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	lxi 	h,0
	push	h
	lxi 	h,20
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	bdos1
	pop 	b
	pop 	b
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL25
	jmp 	LABEL24
LABEL25:
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,128
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
LABEL23:
	lxi 	h,6
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	push	h
	lxi 	h,4
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jnz 	LABEL22
LABEL24:
LABEL21:
	lxi 	h,26
	push	h
	lxi 	h,128
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL26
	lxi 	h,modes
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,3
	pop 	d
	call	ccpint
	lxi 	h,1
	call	ccneg
	jmp 	LABEL12
LABEL26:
	lxi 	h,eptr
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,bptr
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	buffaddr	; in XFgetc
	pop 	b
	pop 	d
	call	ccpint
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,128
	pop 	d
	call	ccmul
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
LABEL20:
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,bptr
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	call	ccgint
	push	h
	lxi 	h,255
	pop 	d
	call	ccand
	pop 	d
	call	ccpint
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,26
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL27
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,1
	call	ccneg
	pop 	d
	call	ccpint
	lxi 	h,modes
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,3
	pop 	d
	call	ccpint
LABEL27:
	lxi 	h,4
	dad 	sp
	call	ccgint
	jmp 	LABEL12
LABEL19:
	lxi 	h,1
	call	ccneg
	jmp 	LABEL12
LABEL12:
	xchg
	lxi 	h,8
	dad 	sp
	sphl
	xchg
	ret
fclose:
	push	b
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	call	cceq
	pop 	d
	call	ccor
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	call	cceq
	pop 	d
	call	ccor
	mov 	a,h
	ora 	l
	jz  	LABEL29
	lxi 	h,0
	jmp 	LABEL28
LABEL29:
	lxi 	h,modes
	push	h
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL30
	lxi 	h,modes
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL31
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	fflush
	pop 	b
LABEL31:
	lxi 	h,modes
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	lxi 	h,16
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	push	h
	mvi 	a,2
	call	bdos1
	pop 	b
	pop 	b
	jmp 	LABEL28
LABEL30:
	lxi 	h,1
	call	ccneg
	jmp 	LABEL28
LABEL28:
	pop 	b
	ret
fflush:
	push	b
	push	b
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	ccne
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	call	ccne
	pop 	d
	call	ccor
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	call	ccne
	pop 	d
	call	ccor
	mov 	a,h
	ora 	l
	jz  	LABEL33
	lxi 	h,26
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	fputc
	pop 	b
	pop 	b
	lxi 	h,bptr
	push	h
	lxi 	h,8
	dad 	sp
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	buffaddr	; in fflush
	pop 	b
	pop 	d
	call	ccpint
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL34
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	pop 	d
	call	ccpint
LABEL35:
	lxi 	h,26
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	lxi 	h,0
	push	h
	lxi 	h,21
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	bdos1
	pop 	b
	pop 	b
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL38
	lxi 	h,1
	call	ccneg
	jmp 	LABEL32
LABEL38:
LABEL36:
	lxi 	h,bptr
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,128
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	pop 	d
	call	ccugt
	mov 	a,h
	ora 	l
	jnz 	LABEL35
LABEL37:
	lxi 	h,26
	push	h
	lxi 	h,128
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
LABEL34:
LABEL33:
	lxi 	h,0
	jmp 	LABEL32
LABEL32:
	pop 	b
	pop 	b
	ret
fputc:
	push	b
	push	b
	lxi 	h,8
	dad 	sp
	call	ccgchar
	push	h
	lxi 	h,10
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL40
	lxi 	h,13
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	fputc
	pop 	b
	pop 	b
LABEL40:
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	call	cceq
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	call	cceq
	pop 	d
	call	ccor
	mov 	a,h
	ora 	l
	jz  	LABEL41
	lxi 	h,2
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgchar
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	lxi 	h,8
	dad 	sp
	call	ccgchar
	jmp 	LABEL39
LABEL41:
	lxi 	h,2
	push	h
	lxi 	h,modes
	push	h
	lxi 	h,10
	dad 	sp
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL42
	lxi 	h,bptr
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,eptr
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	ccuge
	mov 	a,h
	ora 	l
	jz  	LABEL43
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	buffaddr	; in fputc
	pop 	b
	pop 	d
	call	ccpint
LABEL44:
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,eptr
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jz  	LABEL45
	lxi 	h,26
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	lxi 	h,0
	push	h
	lxi 	h,21
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	bdos1
	pop 	b
	pop 	b
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL46
	jmp 	LABEL45
LABEL46:
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,128
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	jmp 	LABEL44
LABEL45:
	lxi 	h,26
	push	h
	lxi 	h,128
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	lxi 	h,bptr
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	buffaddr	; in XFgetC
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,eptr
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jz  	LABEL47
	lxi 	h,1
	call	ccneg
	jmp 	LABEL39
LABEL47:
LABEL43:
	lxi 	h,bptr
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgchar
	pop 	d
	call	ccpint
	lxi 	h,8
	dad 	sp
	call	ccgchar
	jmp 	LABEL39
LABEL42:
	lxi 	h,1
	call	ccneg
	jmp 	LABEL39
LABEL39:
	pop 	b
	pop 	b
	ret
allocunitno:
	push	b
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL49:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,4
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jnz 	LABEL51
	jmp 	LABEL52
LABEL50:
	lxi 	h,0
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	jmp 	LABEL49
LABEL51:
	lxi 	h,modes
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL53
	jmp 	LABEL52
LABEL53:
	jmp 	LABEL50
LABEL52:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,4
	pop 	d
	call	ccuge
	mov 	a,h
	ora 	l
	jz  	LABEL54
	lxi 	h,1
	call	ccneg
	jmp 	LABEL48
	jmp 	LABEL55
LABEL54:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	dad 	d
	jmp 	LABEL48
LABEL55:
LABEL48:
	pop 	b
	ret
fopen:
	push	b
	push	b
	lxi 	h,1
	call	ccneg
	push	h
	lxi 	h,4
	dad 	sp
	push	h
	mvi 	a,0
	call	allocunitno
	pop 	d
	call	ccpint
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL57
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	push	h
	mvi 	a,1
	call	clearfcb
	pop 	b
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,2
	call	movname
	pop 	b
	pop 	b
	lxi 	h,114
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	call	ccgchar
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL58
	lxi 	h,15
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	push	h
	mvi 	a,2
	call	bdos1
	pop 	b
	pop 	b
	push	h
	lxi 	h,255
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL59
	lxi 	h,modes
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,1
	pop 	d
	call	ccpint
	lxi 	h,eptr
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,bptr
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	buffaddr	; in fopen
	pop 	b
	pop 	d
	call	ccpint
	pop 	d
	call	ccpint
	lxi 	h,2
	dad 	sp
	call	ccgint
	jmp 	LABEL56
LABEL59:
	jmp 	LABEL60
LABEL58:
	lxi 	h,119
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	call	ccgchar
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL61
	lxi 	h,19
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	push	h
	mvi 	a,2
	call	bdos
	pop 	b
	pop 	b
	lxi 	h,22
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	fcbaddr
	pop 	b
	push	h
	mvi 	a,2
	call	bdos1
	pop 	b
	pop 	b
	push	h
	lxi 	h,255
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL62
	lxi 	h,modes
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,2
	pop 	d
	call	ccpint
	lxi 	h,bptr
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	buffaddr	; in XFgetC
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,eptr
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	buffaddr	; in XFgetC
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,2
	dad 	sp
	call	ccgint
	jmp 	LABEL56
LABEL62:
LABEL61:
LABEL60:
LABEL57:
	lxi 	h,0
	jmp 	LABEL56
LABEL56:
	pop 	b
	pop 	b
	ret
clearfcb:
	push	b
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL64:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,33
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jnz 	LABEL66
	jmp 	LABEL67
LABEL65:
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,0
	pop 	d
	mov 	a,l
	stax	d
	jmp 	LABEL64
LABEL66:
	jmp 	LABEL65
LABEL67:
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,1
	pop 	d
	call	ccpint
LABEL68:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,12
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jnz 	LABEL70
	jmp 	LABEL71
LABEL69:
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,32
	pop 	d
	mov 	a,l
	stax	d
	jmp 	LABEL68
LABEL70:
	jmp 	LABEL69
LABEL71:
	lxi 	h,4
	dad 	sp
	call	ccgint
	jmp 	LABEL63
LABEL63:
	pop 	b
	ret
movname:
	push	b
	dcx 	sp
	lxi 	h,1
	dad 	sp
	push	h
	lxi 	h,1
	pop 	d
	call	ccpint
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,58
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	call	ccgchar
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL73
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	mvi 	a,1
	call	toupper
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,65
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgchar
	pop 	d
	call	ccle
	push	h
	lxi 	h,66
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgchar
	pop 	d
	call	ccge
	pop 	d
	call	ccand
	mov 	a,h
	ora 	l
	jz  	LABEL74
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgchar
	push	h
	lxi 	h,65
	pop 	d
	call	ccsub
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,5
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	lxi 	h,5
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
LABEL74:
LABEL73:
LABEL75:
	lxi 	h,0
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	call	ccgchar
	pop 	d
	call	ccne
	push	h
	lxi 	h,3
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,9
	pop 	d
	call	ccult
	pop 	d
	call	ccand
	mov 	a,h
	ora 	l
	jz  	LABEL76
	lxi 	h,46
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	call	ccgchar
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL77
	jmp 	LABEL76
LABEL77:
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,7
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	call	ccgchar
	push	h
	mvi 	a,1
	call	toupper
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	jmp 	LABEL75
LABEL76:
LABEL78:
	lxi 	h,0
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	call	ccgchar
	pop 	d
	call	ccne
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	call	ccgchar
	push	h
	lxi 	h,46
	pop 	d
	call	ccne
	pop 	d
	call	ccand
	mov 	a,h
	ora 	l
	jz  	LABEL79
	lxi 	h,5
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	jmp 	LABEL78
LABEL79:
	lxi 	h,5
	dad 	sp
	call	ccgint
	call	ccgchar
	mov 	a,h
	ora 	l
	jz  	LABEL80
	lxi 	h,1
	dad 	sp
	push	h
	lxi 	h,8
	pop 	d
	call	ccpint
LABEL81:
	lxi 	h,0
	push	h
	lxi 	h,7
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	call	ccgchar
	pop 	d
	call	ccne
	push	h
	lxi 	h,12
	push	h
	lxi 	h,5
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	pop 	d
	call	ccugt
	pop 	d
	call	ccand
	mov 	a,h
	ora 	l
	jnz 	LABEL83
	jmp 	LABEL84
LABEL82:
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	call	ccgchar
	push	h
	mvi 	a,1
	call	toupper
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	jmp 	LABEL81
LABEL83:
	jmp 	LABEL82
LABEL84:
LABEL80:
	lxi 	h,7
	dad 	sp
	call	ccgint
	jmp 	LABEL72
LABEL72:
	inx 	sp
	pop 	b
	ret
stdioinit:
	push	b
	lxi 	h,0
	mov 	a,l
	sta 	eofstdin
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL86:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,4
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jnz 	LABEL88
	jmp 	LABEL89
LABEL87:
	lxi 	h,modes
	push	h
	lxi 	h,2
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	dad 	h
	pop 	d
	dad 	d
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	jmp 	LABEL86
LABEL88:
	jmp 	LABEL87
LABEL89:
LABEL85:
	pop 	b
	ret
fcbaddr:
	lxi 	h,fcbs
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,33
	pop 	d
	call	ccmul
	pop 	d
	dad 	d
	jmp 	LABEL90
LABEL90:
	ret
buffaddr:
	lxi 	h,buffs
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,512
	pop 	d
	call	ccmul
	pop 	d
	dad 	d
	jmp 	LABEL91
LABEL91:
	ret
feof:
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	push	h
	lda	eofstdin
	call	ccsxt
	pop 	d
	call	ccand
	mov 	a,h
	ora 	l
	jz  	LABEL93
	lxi 	h,1
	jmp 	LABEL92
LABEL93:
	lxi 	h,modes
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	ccsub
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	push	h
	lxi 	h,3
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL94
	lxi 	h,1
	jmp 	LABEL92
LABEL94:
	lxi 	h,0
	jmp 	LABEL92
LABEL92:
	ret
putchar:
	lxi 	h,2
	dad 	sp
	call	ccgchar
	push	h
	lxi 	h,1
	push	h
	mvi 	a,2
	call	fputc
	pop 	b
	pop 	b
	jmp 	LABEL95
LABEL95:
	ret
strlen:
	push	b
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL97:
	lxi 	h,4
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	call	ccgchar
	mov 	a,h
	ora 	l
	jz  	LABEL98
	lxi 	h,0
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	jmp 	LABEL97
LABEL98:
	lxi 	h,0
	dad 	sp
	call	ccgint
	jmp 	LABEL96
LABEL96:
	pop 	b
	ret
reverse:
	push	b
	push	b
	dcx 	sp
	lxi 	h,3
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	lxi 	h,1
	dad 	sp
	push	h
	lxi 	h,9
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	strlen
	pop 	b
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
LABEL100:
	lxi 	h,3
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	dad 	sp
	call	ccgint
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jz  	LABEL101
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,9
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	call	ccgchar
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,5
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,9
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,5
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	call	ccgchar
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,3
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgchar
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,3
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	lxi 	h,1
	dad 	sp
	push	h
	call	ccgint
	dcx 	h
	pop 	d
	call	ccpint
	inx 	h
	jmp 	LABEL100
LABEL101:
	lxi 	h,7
	dad 	sp
	call	ccgint
	jmp 	LABEL99
LABEL99:
	inx 	sp
	pop 	b
	pop 	b
	ret
puts:
LABEL103:
	lxi 	h,2
	dad 	sp
	call	ccgint
	call	ccgchar
	mov 	a,h
	ora 	l
	jz  	LABEL104
	lxi 	h,2
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	call	ccgchar
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL103
LABEL104:
LABEL102:
	ret
itoa:
	push	b
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL106:
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,10
	pop 	d
	call	ccudiv
	xchg
	push	h
	lxi 	h,48
	pop 	d
	dad 	d
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,10
	pop 	d
	call	ccudiv
	pop 	d
	call	ccpint
	lxi 	h,0
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
LABEL107:
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	ccugt
	mov 	a,h
	ora 	l
	jnz 	LABEL106
LABEL108:
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,0
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	reverse
	pop 	b
LABEL105:
	pop 	b
	ret



base:
	push	b
	lxi 	h,0
	dad 	sp
	push	h
	lhld	dynamicLink
	pop 	d
	call	ccpint
BASE110:
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	ccugt
	mov 	a,h
	ora 	l
	jz  	BASE111
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,interpstk
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	dad 	h
	pop 	d
	dad 	d
	call	ccgint
	pop 	d
	call	ccpint
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
	jmp 	BASE110
BASE111:
	lxi 	h,0
	dad 	sp
	call	ccgint
	jmp 	LABEL109
LABEL109:
	pop 	b
	ret


asciiToChar:
	push	b
	push	b
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	mov 	l,m
	mvi 	h,0
	pop 	d
	call	ccpint
	lxi 	h,6
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,48
	pop 	d
	call	ccuge
	mov 	a,h
	ora 	l
	jz  	LABEL114
	lxi 	h,6
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,57
	pop 	d
	call	ccule
LABEL114:
	call	ccbool
	mov 	a,h
	ora 	l
	jz  	LABEL113
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,48
	pop 	d
	call	ccsub
	pop 	d
	call	ccpint
	jmp 	LABEL115
LABEL113:
	lxi 	h,6
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,65
	pop 	d
	call	ccuge
	mov 	a,h
	ora 	l
	jz  	LABEL117
	lxi 	h,6
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,70
	pop 	d
	call	ccule
LABEL117:
	call	ccbool
	mov 	a,h
	ora 	l
	jz  	LABEL116
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,65
	pop 	d
	call	ccsub
	push	h
	lxi 	h,10
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	jmp 	LABEL118
LABEL116:
	lxi 	h,STR$OPNNG	;LABEL0+0
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,6
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	mvi 	a,1
	call	printbyte
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,88
	pop 	d
	call	ccpint
LABEL118:
LABEL115:
	lxi 	h,2
	dad 	sp
	call	ccgint
	jmp 	LABEL112
LABEL112:
	pop 	b
	pop 	b
	ret
asciiToByte:
	dcx 	sp
	dcx 	sp
	dcx 	sp
	lxi 	h,1
	dad 	sp
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	mvi 	a,1
	call	asciiToChar
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	mvi 	a,1
	call	asciiToChar
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,3
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,16
	pop 	d
	call	ccmul
	push	h
	lxi 	h,4
	dad 	sp
	mov 	l,m
	mvi 	h,0
	pop 	d
	dad 	d
	push	h
	lxi 	h,255
	pop 	d
	call	ccand
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	jmp 	LABEL119
LABEL119:
	inx 	sp
	pop 	b
	ret


parseDataRecord:
	push	b
	dcx 	sp
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,11
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lhld	highWater
	pop 	d
	call	ccugt
	mov 	a,h
	ora 	l
	jz  	LABEL121
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,11
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	shld	highWater
LABEL121:
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	lhld	startingOffset
	pop 	d
	call	ccsub
	push	h
	lxi 	h,11
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,MEMSIZE
	pop 	d
	call	ccuge
	mov 	a,h
	ora 	l
	jz  	LABEL122
	;lxi 	h,LABEL0+26
	lxi 	h,STR$UNKNOWN
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	mvi 	a,0
	call	exit
	jmp 	LABEL123
LABEL122:
	lxi 	h,1
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL124:
	lxi 	h,1
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,11
	dad 	sp
	call	ccgint
	pop 	d
	call	ccult
	mov 	a,h
	ora 	l
	jnz 	LABEL126
	jmp 	LABEL127
LABEL125:
	lxi 	h,1
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	jmp 	LABEL124
LABEL126:
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,7
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	asciiToByte
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,5
	dad 	sp
	push	h
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	lxi 	h,memory
	push	h
	lxi 	h,9
	dad 	sp
	call	ccgint
	push	h
	lhld	startingOffset
	pop 	d
	call	ccsub
	push	h
	lxi 	h,5
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	pop 	d
	dad 	d
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgchar
	pop 	d
	mov 	a,l
	stax	d
	jmp 	LABEL125
LABEL127:
LABEL123:
LABEL120:
	inx 	sp
	pop 	b
	ret



printhex:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL129
	lxi 	h,48
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL130
LABEL129:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL131
	lxi 	h,48
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL132
LABEL131:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,1
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL133
	lxi 	h,49
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL134
LABEL133:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,2
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL135
	lxi 	h,50
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL136
LABEL135:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,3
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL137
	lxi 	h,51
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL138
LABEL137:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,4
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL139
	lxi 	h,52
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL140
LABEL139:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,5
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL141
	lxi 	h,53
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL142
LABEL141:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,6
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL143
	lxi 	h,54
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL144
LABEL143:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,7
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL145
	lxi 	h,55
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL146
LABEL145:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,8
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL147
	lxi 	h,56
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL148
LABEL147:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,9
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL149
	lxi 	h,57
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL150
LABEL149:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,10
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL151
	lxi 	h,65
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL152
LABEL151:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,11
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL153
	lxi 	h,66
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL154
LABEL153:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,12
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL155
	lxi 	h,67
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL156
LABEL155:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,13
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL157
	lxi 	h,68
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL158
LABEL157:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,14
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL159
	lxi 	h,69
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL160
LABEL159:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,15
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL161
	lxi 	h,70
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	jmp 	LABEL162
LABEL161:
	lxi 	h,63
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
LABEL162:
LABEL160:
LABEL158:
LABEL156:
LABEL154:
LABEL152:
LABEL150:
LABEL148:
LABEL146:
LABEL144:
LABEL142:
LABEL140:
LABEL138:
LABEL136:
LABEL134:
LABEL132:
LABEL130:
LABEL128:
	ret



printbyte:
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,4
	pop 	d
	call	cclsr
	push	h
	lxi 	h,15
	pop 	d
	call	ccand
	push	h
	mvi 	a,1
	call	printhex
	pop 	b
	lxi 	h,2
	dad 	sp
	mov 	l,m
	mvi 	h,0
	push	h
	lxi 	h,15
	pop 	d
	call	ccand
	push	h
	mvi 	a,1
	call	printhex
	pop 	b
LABEL163:
	ret



printword:
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,12
	pop 	d
	call	cclsr
	push	h
	lxi 	h,15
	pop 	d
	call	ccand
	push	h
	mvi 	a,1
	call	printhex
	pop 	b
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,8
	pop 	d
	call	cclsr
	push	h
	lxi 	h,15
	pop 	d
	call	ccand
	push	h
	mvi 	a,1
	call	printhex
	pop 	b
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,4
	pop 	d
	call	cclsr
	push	h
	lxi 	h,15
	pop 	d
	call	ccand
	push	h
	mvi 	a,1
	call	printhex
	pop 	b
	lxi 	h,2
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,15
	pop 	d
	call	ccand
	push	h
	mvi 	a,1
	call	printhex
	pop 	b
LABEL164:
	ret



parseLine:
	push	b
	push	b
	push	b
	push	b
	push	b
	lxi 	h,8
	dad 	sp
	push	h
	lxi 	h,1
	pop 	d
	call	ccpint
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	lxi 	h,0
	shld	dataIndex
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL166:
	lxi 	h,12
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	lxi 	h,58
	pop 	d
	call	ccne
	mov 	a,h
	ora 	l
	jz  	LABEL168
	lxi 	h,6
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,256
	pop 	d
	call	ccult
LABEL168:
	call	ccbool
	mov 	a,h
	ora 	l
	jz  	LABEL167
	lxi 	h,6
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	jmp 	LABEL166
LABEL167:
	lxi 	h,12
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	lxi 	h,58
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL169
	lxi 	h,6
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
	jmp 	LABEL170
LABEL169:
	lxi 	h,0
	jmp 	LABEL165
LABEL170:
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	asciiToByte
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	ccuge
	mov 	a,h
	ora 	l
	jz  	LABEL171
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	jmp 	LABEL172
LABEL171:
	lxi 	h,0
	jmp 	LABEL165
LABEL172:
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	asciiToByte
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,256
	pop 	d
	call	ccmul
	push	h
	lxi 	h,16
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	asciiToByte
	pop 	b
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	lhld	foundStartAddress
	call	cclneg
	mov 	a,h
	ora 	l
	jz  	LABEL173
	lxi 	h,2
	dad 	sp
	call	ccgint
	shld	startingOffset
	lxi 	h,1
	shld	foundStartAddress
LABEL173:
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,14
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,10
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	mvi 	a,1
	call	asciiToByte
	pop 	b
	pop 	d
	call	ccpint
	lxi 	h,6
	dad 	sp
	push	h
	lxi 	h,8
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,2
	pop 	d
	dad 	d
	pop 	d
	call	ccpint
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL174
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,16
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,12
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	mvi 	a,3
	call	parseDataRecord
	pop 	b
	pop 	b
	pop 	b
	lxi 	h,8
	dad 	sp
	push	h
	lxi 	h,1
	pop 	d
	call	ccpint
	jmp 	LABEL175
LABEL174:
	lxi 	h,0
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,1
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL176
	lxi 	h,8
	dad 	sp
	push	h
	lxi 	h,1
	pop 	d
	call	ccpint
	jmp 	LABEL177
LABEL176:
LABEL177:
LABEL175:
	lxi 	h,8
	dad 	sp
	call	ccgint
	jmp 	LABEL165
LABEL165:
	xchg
	lxi 	h,10
	dad 	sp
	sphl
	xchg
	ret



parseHex2:
	xchg
	lxi 	h,-256
	dad 	sp
	sphl
	xchg
	push	b
	dcx 	sp
	dcx 	sp
	lxi 	h,STR$OPNNG	;LABEL0+0
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,262
	dad 	sp
	call	ccgint
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,0
	dad 	sp
	push	h
	lxi 	h,264
	dad 	sp
	call	ccgint
	push	h
	lxi 	h,STR$FREAD		;LABEL0+9
	push	h
	mvi 	a,2
	call	fopen
	pop 	b
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,0
	dad 	sp
	call	ccgchar
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL179
	lxi 	h,STR$NOFILE		;LABEL0+11
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,0
	shld	parsedHexOK
	jmp 	LABEL178
LABEL179:
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
LABEL180:
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,2
	dad 	sp
	call	ccgchar
	push	h
	mvi 	a,1
	call	fgetc
	pop 	b
	pop 	d
	mov 	a,l
	stax	d
	push	h
	lxi 	h,0
	pop 	d
	call	ccge
	mov 	a,h
	ora 	l
	jz  	LABEL181
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	call	ccgchar
	push	h
	lxi 	h,32
	pop 	d
	call	cclt
	mov 	a,h
	ora 	l
	jz  	LABEL182
	lxi 	h,4
	dad 	sp
	push	h
	lxi 	h,4
	dad 	sp
	call	ccgint
	pop 	d
	dad 	d
	push	h
	lxi 	h,0
	pop 	d
	mov 	a,l
	stax	d
	lxi 	h,4
	dad 	sp
	push	h
	mvi 	a,1
	call	parseLine
	pop 	b
	lxi 	h,2
	dad 	sp
	push	h
	lxi 	h,0
	pop 	d
	call	ccpint
	jmp 	LABEL183
LABEL182:
	lxi 	h,2
	dad 	sp
	push	h
	call	ccgint
	inx 	h
	pop 	d
	call	ccpint
	dcx 	h
LABEL183:
	jmp 	LABEL180
LABEL181:
	lxi 	h,1
	shld	parsedHexOK
	jmp 	LABEL178
LABEL178:
	xchg
	lxi 	h,260
	dad 	sp
	sphl
	xchg
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:
	push	b
	lxi 	h,0
	shld	foundStartAddress
	lxi 	h,0
	shld	highWater
	;'starting...'
	lxi 	h,STR$STRTNG		; LABEL0+210
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lhld	Xargc
	push	h
	lxi 	h,0
	pop 	d
	call	cceq
	mov 	a,h
	ora 	l
	jz  	LABEL277

	;'expected a command line with program name and file name'
	lxi 	h,STR$PARAMS		; LABEL0+222
	push	h
	mvi 	a,1
	call	puts
	pop 	b

	; we have no parameter, just run the "pre-programmed"
	; program we have in the program area
	mvi 	a,0
	call	interpret

	jmp 	EXIT1	;LABEL278

LABEL277:
	;'Pascal program we are running is:'
	lxi 	h,STR$PRGINFO		; LABEL0+278
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,dataLine
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,dataLine
	push	h
	mvi 	a,1
	call	parseHex2
	pop 	b
	lhld	parsedHexOK
	mov 	a,h
	ora 	l
	jz  	LABEL279

	;'Hex file ok... TinyPascal PCode Interpreter, July xx 2025'
	lxi 	h,STR$DATE		;LABEL0+312
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lhld	highWater
	push	h
	lhld	startingOffset
	pop 	d
	call	ccsub
	shld	highWater

	;'memory used:'
	lxi 	h,STR$MEM		;LABEL0+368
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lhld	highWater
	push	h
	mvi 	a,1
	call	printword
	pop 	b
	
	; ' of max:'
	lxi 	h,STR$MMAX		;LABEL0+381
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,MEMSIZE
	push	h
	mvi 	a,1
	call	printword
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b

	mvi 	a,0
	call	interpret
	jmp 	EXIT1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LABEL279:
	;'issue parsing input file'
	lxi 	h,STR$PARSX		;LABEL0+390
	push	h
	mvi 	a,1
	call	puts
	pop 	b
	lxi 	h,10
	push	h
	mvi 	a,1
	call	putchar
	pop 	b
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
EXIT1:
	lxi 	h,0
	push	h
	mvi 	a,1
	call	exit
	pop 	b
FINIS
	pop 	b
	ret

	; LABEL0+26
STR$UNKNOWN: db	'string 26 here???',0

	; LABEL0+0
STR$OPNNG: db	'opening ',0 				

	;+9 	= LABEL0+9
STR$FREAD: db	'r',0					

	;+2	= LABEL0+11
STR$NOFILE: db	'Failed to open the file.',0		

	;+25	= LABEL0+36
STR$VERS: db	'version:',0				

	;+9	= LABEL0+45
STR$BADVER: db	'Version incorrect, exiting',0

	;+27 	= LABEL0+72
STR$DOTDOT: db	'case opr_dotdot_set16 not implemented yet',0

	;+42	= LABEL0+114
STR$BBND: db	'BBOUND not implemented yet',0

	;+27	= LABEL0+141
STR$UNKTYP: db	'interpret, unknown type',0

	;+24 	= LABEL0+165
STR$NORMAL: db	'... program completed normally',0

	;+31	= LABEL0+196
STR$INVINS: db	'INVALID INSTR',0AH,0

	;+14	= LABEL0+210
STR$STRTNG: db	'starting...',0
	
	;+12	= LABEL0+222
STR$PARAMS:
	db	'expected a command line with program name and file name',0AH,0

	;+57 	= LABEL0+278
STR$PRGINFO:
	db	'Pascal program we are running is:',0

	;+34	= LABEL0+312
STR$DATE:
	db	'Hex file ok! TinyPascal PCode Interpreter, July 27 2025',0

	; LABEL0+368
STR$MEM:
	db	'memory used:',0

	; LABEL0+381
STR$MMAX:
	db	' of max:',0

STR$PARSX:
	; LABEL0+390
	db	'issue parsing input file',0

STR$UNKOPR: db	'interpret, OPR not supported yet',0

; global variables
count:	dw	0

;;;;;;;;;;;;;;;;;;;;;;;;;
;top of stack
;
; we assume stack is 16 byte entries
;
; rca1802mode if set (or R1802MODE is set), the
; tops content is specified in bytes, so 2x more.
;  
topOfStk:	dw	0

;interp dynamic link, program pointer
dynamicLink: dw	0
progPtr:     dw	0
ax:          dw	0
lv:          dw	0

;current PCode instruction we are working on
instr: dw	0

rv: dw	0

;;;;;;;;;;;;;;;;;;;;;;;;
;
; rca1802mode, we pre-multiply some numbers,
; to not have to do get "16 bit" indexes into "byte indexes"
; this should match R1802MODE being set for our assembler stuff

rca1802mode: dw	1


nbuf:
	db	0,0,0,0,0,0,0,0,0,0

Xargc:
	dw	0

bptr:
	dw	0,0,0,0
modes:
	dw	0,0,0,0
eptr:
	dw	0,0,0,0
eofstdin:
	db	0
parsedHexOK:
	dw	0
dataIndex:
	dw	0
startingOffset:
	dw	0
highWater:
	dw	0
foundStartAddress:
	dw	0

fcbs:
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0

dataLine:
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; memory for our MCode program code:
memory:
TESTMODE	EQU	TRUE
	IF	TESTMODE
	; put a program here, zero based, to print out a message
	; sometime. For now, we put test programs here to test
	; with ddt6.com
	
;8800                 PASPROG    EQU ORGINIT + 0800H
;   8800                           ORG  PASPROG
;
;
;                        ;      0  ver  012343
;   8800   00                      DB        OPVER
;   8801   30 37                   DW     12343
	DB	00H, 30H, 37H
;
;                        ;      2  int  0    3
;   8806                 LINE2
;   8806   0e                      DB        OPINT
;   8807   00 06                   DW     (3 SHL 1)
	DB	0EH, 00H, 06H
;
;                        ;      3  lit  0  333
;   8809   02                      DB        OPLIT
;   880a   01 88                   DW       XXX
	DB	02H, 00H, 03H
;
;                        ;      4  lit  0  789
;   880c   02                      DB        OPLIT
;   880d   02 22                   DW       YYY
; only need 1
;	DB	02H, 03H, 15H


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FLIP TOS
	DB 08H, 64H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; AND
;	DB 08H, 48H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INTTOSET16
	DB 08H, 54H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;                        ;      5  opr  0    1
;   880f   08                      DB        OPOPR
;   8810   04                      DB        (1 SHL 2) ; instr2, ax, opr
	DB	08H, 54H
;
;                        ;      6 txot  2    0
;   8811   1c                      DB        TXOUT
;   8812   02                      DB      2   ; instr2 not opr, so using level
;   8813   00 00                   DW     0 ; uint16, on stack
	DB 1CH, 02H, 00H, 00H
; second on stack:
;	DB 1CH, 02H, 00H, 00H

                        ;      8  xit  0    0
;   8819   20                      DB        OPXIT
	DB 020H

 ;881a                 CONSTCHARTXT
 ;  881a   0d                      DB          13    ; 
 ;  881b   0a                      DB          10    ;
 ;  881c   00                      DB           0    ;     

CRLF:
	DB 0DH, 0AH, 00H

	ENDIF
	; zero the first couple of bytes
	db	0,0,0,0,0,0,0,0,0,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG memory+MEMSIZE

peekPokeMem:
	; zero the first couple of bytes
	db	'+','+','+','+','+','+','+','+'
	db	'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
	db	'm','i','s','t','a','k','e','!'
	db	'D','E','A','D','B','E','E','F'
	
	db	0,0,0,0,0,0,0,0,0,0
	ORG peekPokeMem+PPMEMSIZE


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
buffs:
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0

interpstk:
	; zero the first couple of bytes
	dw	0,0,0,0,0,0,0,0,0,0
	dw	0,0,0,0,0,0,0,0,0,0



; and just let the interpreter stack go on forever...

; so this has to be the highest memory, so leave at end!

END
