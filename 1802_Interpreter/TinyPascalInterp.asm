;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tiny Pascal interpreter for the 1802.
;
; 
; * This file is part of the TinyPascal for the RCA 1802 distribution 
; * (https://github.com/xxxx or http://xxx.github.io).
; * Copyright (c) 2025 John A. Stewart.
; * 
; * This program is free software: you can redistribute it and/or modify  
; * it under the terms of the GNU General Public License as published by  
; * the Free Software Foundation, version 3.
; *
; * This program is distributed in the hope that it will be useful, but 
; * WITHOUT ANY WARRANTY; without even the implied warranty of 
; * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
; * General Public License for more details.
; *
; * You should have received a copy of the GNU General Public License 
; * along with this program. If not, see <http://www.gnu.org/licenses/>.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; last edit - Apr 28 2025 - working on uint16 division
;
; March 28 2025
; for set handling (16 bit sets only on this iteration)  
;        {Set word-wide (16 bit) operators}
;        const opr_or_set     
;        const opr_and_set    
;        const opr_dotdot_set 
;        const opr_difference_set
;

; Feb 11 2025
; shrinking pcode size by removing unused fields in each instruction.
;
;
; Jan 4 2025
; HELLOSTRING printing moved up a bit, so the interpreter
; stack is not overwritten.
; - VER moved to being an instruction, not an operation,
; so no writing on the stack and overwriting... even though
; it no longer prints the "OK!" string. Safer...
; 
;
; Dec 28 - removing some prints; at the start, the hellostring
; overwrites the SL, DL of the main frame, as SP is set to FEFF
; and the SCRT call uses stack.
; -- anything between the "CAL" and "INT" will overwrite the 
; stack...
; so the HELLOSTRING and OK! have been removed from printing.
; to fix, because these start up before any/much interpreter code
; is running, but AFTER setup, stack gets overwritten by the SCRT
; code.
; right now, they are coded out by ;NO
;
; Dec 21 2024
;   - OPCAL - decrement stack before storing it; trying a fix;
;
; Dec 03 2024
;   - Version changed to 03
;   - working on filling out OPOPR table.

;
; Nov 10 2024
;   - function return values; procedure/fn STK operations for 
;     loading parameters onto the stack.
;   - OPRSUB was wrong, see code. Now subtracts if LHS > 256.
;
; Sept 25 2024
; - renamed from PL0Interpreter to Tiny Pascal Interpreter;
; - implemented a "Jump Table" for operations;
;
; Aug 27 2024 - working on "write" and "writeln" of numbers and char strings.
;
; July 28; fixed a problem in GETBASE, now highly
; recursive test seems to work as expected. 
;
; July 25, call/return seems to be better now.
; 
; July 24, Dynamic linking not correct on CALL.
; will have to re-visit getBase function, and
; return...
;
; July 18, sending this to laptop for work on
; trying to figure out how my recursive test
; with conditional fails.
;
; July 16, working slowly on recursive test and
; static and dynamic linking. Moved the "trace" calls
; around a bit; don't want them to smash the stack
; initializations before the OPINIT is called.
;
; update July 12, I think call/return works ok now.
;
; Error/info prints
;	'FINISH'	- end of program, normal exit.
;	'OP?'		- OPCODE OPERATION (eg, DIV, MUL, SHL...) not coded yet.
;	'DIVby0'	- OPCODE UDIV, denominator is zero.
;	'DIVoflo'	- OPCODE UDIV, if Numerator too large, code doesn't work.
; 	'OPCODE?'	- Bad opcode, likely program counter messed or memory overwritten
;	
; To add more, look for "HELLOSTRING" and how it is printed.
; two routines you can LBR to;
;    -set null terminated string address in TPTMP1, then branch to:
;    -TX_LOOP     - prints message and continues
;    -TX_FIN_LOOP - prints message and exits
; Dec 21 2024
;   - OPCAL - decrement stack before storing it; trying a fix;
;
; 
;Register usage
;R0.0	temp D reg storage in SCRT I/O routines
;R2	Shared (SCRT, etc) Stack Pointer
;R3	Running Program Counter
;R4	SCRT “Call” routine pointer
;R5	SCRT “Return” routine pointer
;R6	TMP:
;		SCRT picking up SCRTLINK
;
;RB	SCRT Data Register - character in RB.0 for output
;RE	Monitor Serial Parameters


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Version.
;
; ASCII number encoded here. ASCII because it makes printing
; very easy for error messages.
;
; IF we decide to print the error message with versions, if
; not, just re-compile the compiler and this interpreter and
; cross fingers, I did the versioning correctly!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; SCRT calls
STACKREG   	EQU 002H ;Shared stack.
SCRTPC	   	EQU 003H ;main Program Control reg, is standard SCRT return
SCRTCALL   	EQU 004H ;CALL ROUTINE REGISTER
SCRTRETN   	EQU 005H ;RETURN ROUTINE REGISTER
SCRTLINK   	EQU 006H ;SUBROUTINE.DATA LINK (return stack)

; Interpreter
TPASPC     	EQU 007H ; Interpreter main Program Counter
GETBASE    	EQU 008H ; Interpreter get base function
CURFRAME_DYNAM_LINK   	EQU 001H ; current top "frame" for variables on stack 

; temp registers
TPTMP0		EQU 000H ; tmp register for TinyPascal interpreter
TPTMP1		EQU 009H ; tmp register for TinyPascal interpreter
TPTMP2		EQU 00AH ; tmp register for TinyPascal interpreter
BASE_RET_STATIC_LINK		EQU TPTMP2 ; return variable address in stack
TPTMP3		EQU 00BH ; 8-bit tmp register can be used in B.1
		; *NOTE* B.0 is used in SCRT Char out routines.

; MC20ANSA Serial registers
DATAREG    	EQU 00BH ;MC20ANSA out char in B.0
SERPARAM   	EQU 00EH ;MC20ANSA uses E.0 for sw serial parameters

; Stack - on start, and on a procedure call, we have three 16-bit markers;
;	SL - Dynamic Link
;	RA - Return Address
;	SL - Static Link

; OPCODES 
; See the TinyPascal compiler, updated Feb 11 2025
;
; for Interpreter, each OPCODE takes up to 4 bytes:
;    1   : OPCODE,
;    2   : LEVEL,
;    3,4 : ADDRESS


OPVER      EQU 000H 
OPLIT      EQU 001H 
OPLOD      EQU 002H
OPSTO      EQU 003H 
OPOPR      EQU 004H 
BBOUND     EQU 005H   
OPSTK      EQU 006H 
OPINT      EQU 007H
OPPCAL     EQU 008H 
OPFCAL     EQU 009H 
OPPRET     EQU 00AH   
OPFRET     EQU 00BH 
OPJMP      EQU 00CH
OPJPC      EQU 00DH
TXOUT      EQU 00EH
TXTIN      EQU 00FH
OPXIT      EQU 010H

;;;;;;;;;;;;;;;;;;
; trying different call/return stack arrangements

STACKTESTING EQU 1
ORIGSTACKCODE	EQU 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; Do we fit this into 0x0000 -> 0x7FFF or 0x8000 -> 0xFFFF?
; Lee Hart's MemberCHIP card ROM is 0x0000, the SHIP card is at 0x8000
; Choose one of these to set the RAM block for us to go into
; MEMBERCHIP rom is at 0x0000, ram starts at 0x8000
; MEMBERSHIP rom is at 0x0000, ram starts at 0x0000
;
; Note that, it appears that on running the Emma-O2 emulator that some
; high ROM memory is used, so the STACKST has about 128 bytes reserved
; for that.

MEMBERSHIP EQU     0 ; 1 == memberSHIP card - must set MC20ANSA as well.
MEMBERCHIP EQU     1 ; 1 == memberCHIP card - must set MC20ANSA as well.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; MC20ANSA - default EPROM for Lee Hart's MemberCHIP card, but use for
; both MemberSHIP and MemberCHIP cards; tested with MCSMP20J.bin for
; MemberSHIP cards (Shows Ver. 2.0J on start) and MC20ANSA shows
; v2.0AR 14 Feb 2022. Other versions likely ok, but need to ensure serial
; function addresses are correct.

MC20ANSA   EQU     1

	IF MEMBERCHIP
; MemberCHIP card: ROM at 0000H
; MemberCHIP card: RAM at 8000H
ORGINIT    EQU     08000H
ROMISAT    EQU     0
STACKST	EQU	0FF7FH
	ENDI ; memberCHIP card

	IF MEMBERSHIP
; MemberSHIP card: ROM at 8000H
; MemberSHIP card: RAM at 0000H
ORGINIT     EQU    0
ROMISAT     EQU     08000H
STACKST	EQU	07F7FH
	ENDI ; memberSHIP card

	IF MC20ANSA
	; Monitor entry points 
CHAR_IN_MAIN    EQU 005H + ROMISAT
CHAR_OUT_MAIN   EQU 0021DH + ROMISAT
COLD_START	EQU 00B00H + ROMISAT
	ENDI ; MC20ANSA

	IF MC20ANSA
MC20SREG 	EQU	0EH ; where serial parameters are stored for the Monitor
	ENDI

; where the users' program should reside
PASPROG EQU     ORGINIT + 0800H
; PAGES
PAGE1 EQU     ORGINIT + 0100H
PAGE2 EQU     ORGINIT + 0200H
PAGE3 EQU     ORGINIT + 0300H
PAGE4 EQU     ORGINIT + 0400H
PAGE5 EQU     ORGINIT + 0500H
PAGE6 EQU     ORGINIT + 0600H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start here, setup, then go 
	
	ORG	ORGINIT

	; STACK
	; MC20ANSA uses some ram FFFx area, so we go a bit lower.
	;
	; CURFRAME_DYNAM_LINK - the primary variable stack frame is at the
	; beginning of the stack; it is initialized below.
	LDI	HIGH	STACKST
	PHI	STACKREG
	PHI	CURFRAME_DYNAM_LINK
	LDI	LOW	STACKST
	PLO	STACKREG
	PLO	CURFRAME_DYNAM_LINK
	SEX	STACKREG	; INIT code X->STACKREG default setting

	; SCRT calls
	LDI     HIGH SCRT_CALL
	PHI     SCRTCALL
	LDI     LOW SCRT_CALL
	PLO     SCRTCALL
	LDI     HIGH SCRT_RETURN
	PHI     SCRTRETN
	LDI     LOW SCRT_RETURN
	PLO     SCRTRETN

	; TinyPascal Interpreter program main 
	LDI     HIGH INTERPST
	PHI     SCRTPC
	LDI     LOW INTERPST
	PLO     SCRTPC
	; set P and continue the initialization
	SEP     SCRTPC

INTERPST
	; print out HELLO string here, before we 
	; set everything up for interpreting.
	LDI	HIGH	HELLOSTRING
	PHI	TPTMP1
	LDI	LOW	HELLOSTRING
	PLO	TPTMP1
STX_LOOP
	SEX	TPTMP1		; TX_LOOP, Set X here to point to string
	LDXA
	SEX	STACKREG	; TX_LOOP, return X to default STACKREG
	BZ	FIN_HELLO_STR	; done, got the null at end of string
	PLO	DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN
	; ensure X is set to stackreg 
	BR	STX_LOOP
FIN_HELLO_STR
	
	; done the "HELLLLO!" string, now put the stack 
	; and registers into "interpret" mode.

	; TinyPascal "Program Counter"
	LDI     HIGH PASPROG
	PHI     TPASPC
	LDI     LOW PASPROG
	PLO     TPASPC
	
	; TinyPascal Base function
	LDI	HIGH	BASEFUNC
	PHI	GETBASE
	LDI	LOW	BASEFUNC
	PLO	GETBASE

	; initialize the stack to return:
	; [0,1] :base:	stack base on start
	; [2,3] :b:	stack base on start
	; [4,5] :p:	0
	; CURFRAME_DYNAM_LINK will point to [0] on this stack for the entry level.

	LDI	HIGH	STACKST
	STXD	
	LDI	LOW	STACKST
	STXD	
	; b 
	LDI	HIGH	STACKST
	STXD	
	LDI	LOW	STACKST
	STXD	
	; and finally p
	LDI	00H
	LDI	HIGH	PASPROG
	STXD	
	LDI	LOW	PASPROG
	STXD	
	; and return stack pointing to empty stack.
	LDI	LOW	STACKST
	PLO	STACKREG

	; and, start interpreting PCODE.
	LBR	INTERP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SCRT Call and Return
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; STANDARD CALL

EXITC SEP SCRTPC             ;GO TO CALLED ROUTINE

SCRT_CALL 
	SEX STACKREG 	    ;SCRT_CALL; SET R(X) - should be by default
	GHI SCRTLINK
	STXD                ;SAVE THE CURRENT LINK ON
	GLO SCRTLINK
	STXD                ;THE STACK
	GHI SCRTPC
	PHI SCRTLINK
	GLO SCRTPC
	PLO SCRTLINK
	LDA SCRTLINK
	PHI SCRTPC          ;PICK UP THE SUBROUTINE
	LDA SCRTLINK
	PLO SCRTPC          ;ADDRESS
	BR EXITC

;  STANDARD RETURN

EXITR SEP SCRTPC             ;GO TO CALLED ROUTINE
SCRT_RETURN 
	GHI SCRTLINK            ;recover calling program return addr
	PHI SCRTPC
	GLO SCRTLINK
	PLO SCRTPC
	SEX STACKREG		; SCRT_RETURN set R(X) - should be by default
	INC STACKREG              ;SET THE STACK POINTER
	LDXA
	PLO SCRTLINK            ;RESTORE THE CONTENTS OF
	LDX
	PHI SCRTLINK            ;LINK
	BR EXITR


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Output strings for interpreter messages.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MY_VERSION	EQU	'06'		; for checking, also doubles as visual indicator

; HELLOSTRING. Version number is encoded as year month day

HELLOSTRING
	DB	'T'
	DB	'i'
	DB	'n'
	DB	'y'
	DB	'P'
	DB	'a'
	DB	's'
	DB	'c'
	DB	'a'
	DB	'l'
	DB	' '
	DB	'2'
	DB	'0'
	DB	'2'
	DB	'5'
	DB	'-'
	DB	'0'
	DB	'4'
	DB	'-'
	DB	'2'
	DB	'9'
	DB	' '
	DB	'V'
	DW	MY_VERSION
	DB	0DH
	DB	0AH
	DB	0

; string printed when exit normally
PROGRAM_FINISH
	DB	'F'
	DB	'i'
	DB	'n'
	DB	'i'
	DB	's'
	DB	'h'
	DB	0DH
	DB	0AH
	DB	0

DIV_BY_ZERO
	DB	'D'
	DB	'I'
	DB	'V'
	DB	'b'
	DB	'y'
	DB	'0'
	DB	0DH
	DB	0AH
	DB	0

DIV_OVERFLOW
	DB	'D'
	DB	'I'
	DB	'V'
	DB	'o'
	DB	'f'
	DB	'l'
	DB	'o'
	DB	0DH
	DB	0AH
	DB	0

; bad opcode
OPCODE_BAD
	DB	'O'
	DB	'P'
	DB	'C'
	DB	'O'
	DB	'D'
	DB	'E'
	DB	'?'
	DB	0DH
	DB	0AH
	DB	0

; bad operator
OP_BAD
	DB	'O'
	DB	'P'
	DB	'?'
	DB	0DH
	DB	0AH
	DB	0

; printing to console, have a data type that is not
; yet supported for printing
TYPE_NOT_SUPPORTED
	DB	'T'
	DB	'Y'
	DB	'P'
	DB	'E'
	DB	'?'
	DB	0DH
	DB	0AH
	DB	0
	
; print that we have a version mismatch
VERSION_BAD
	DB	'V'
	DB	'e'
	DB	'r'
	DB	's'
	DB	'i'
	DB	'o'
	DB	'n'
	DB	' '
	DB	'B'
	DB	'A'
	DB	'D'
	DB	0DH
	DB	0AH
	DB	0




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; page code at a page boundary.
	ORG     PAGE1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; This MUST be at a page boundary. 
;
; It implements a "jump table" so that instructions (that
; are in the range to 00H to 0AH are easily "jumped" to.
; The interpreter (this program) takes the instruction,
; multiplies it by 2 (to get an address of a 2 byte space)
; then puts that in the program counter (register pointed to
; by P). The contents of this points to a "Branch to..." to
; run the specific opcode.

; OPCODE jump table
	BR       OPVERJMP   ;   EQU 000H 
	BR       OPLITCODE  ;   EQU 001H 
	BR       OPLODCODE  ;   EQU 002H
	BR       OPSTOCODE  ;   EQU 003H 
	BR       OPOPRJMP   ;   EQU 004H 
	BR       BBOUNDJMP  ;   EQU 005H   
	BR       OPSTKJMP   ;   EQU 006H 
	BR       OPINTCODE  ;   EQU 007H
	BR       OPPCALCODE ;   EQU 008H 
	BR       OPFCALCODE ;   EQU 009H 
	BR       OPPRETJMP  ;   EQU 00AH   
	BR       OPFRETJMP  ;   EQU 00BH 
	BR       OPJMPCODE  ;   EQU 00CH
	BR       OPJPCCODE  ;   EQU 00DH
	BR       OPTXOJMP   ;   EQU 00EH
	BR       OPTXIJMP   ;   EQU 00FH
	BR       OPXITJMP   ;   EQU 010H

	; fill in a few more, maybe will catch an error?
	; we can fill this page up, might help... :-|

	BR OPOPRBAD  ;   empty - not implemented yet
	BR OPOPRBAD  ;   empty - not implemented yet
	BR OPOPRBAD  ;   empty - not implemented yet
	BR OPOPRBAD  ;   empty - not implemented yet
	BR OPOPRBAD  ;   empty - not implemented yet

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; MAIN LOOP - after running 1 interpreted instruction,
	; loop back here.
	;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INTERP
	; get OPCODE

	LDA	TPASPC	; get the opcode pre-multiplied by 2
	PLO	SCRTPC	; jump to it ("it" is a short branch) 

	; for intsructions that do not fit onto this code page,
	; we long branch to them. Hopefully, the ones on THIS 
	; page are the most referred to instructions, reason
	; only for top speed...

OPOPRJMP	LBR	OPOPRCODE ;      EQU 001H
OPTXOJMP	LBR	OPTXOUT	  ;	 EQU 00AH
OPTXIJMP	LBR	OPTXIN	  ;	 EQU 00AH
OPXITJMP	LBR	OPXITCODE ;	 EQU 008H
OPSTKJMP	LBR	OPSTKCODE ;      EQU 00CH
OPPRETJMP	LBR	OPPRETCODE ;	 EQU 009H
OPFRETJMP	LBR	OPFRETCODE ;	 EQU 009H
OPVERJMP	LBR	OPVERCODE ;      EQU 00DH

; bound checking not implemented yet.This is a place holder
BBOUNDJMP

OPOPRBAD
	; if here, something wrong
	LDI	HIGH	OPCODE_BAD
	PHI	TPTMP1
	LDI	LOW	OPCODE_BAD
	PLO	TPTMP1
	LBR	TX_FIN_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPLITCODE
	;    t := t+1; s[t] = a
	;    DB OPLIT
	;    IGNORE DB 0
	;    DW 20
	; IGNORE get level - ignore this
	; IGNORE LDA     TPASPC
	;get  address
	; push high byte then low byte, eg DW 020H push 00 then 20
	LDA     TPASPC
	STXD
	LDA     TPASPC
	STXD
	BR      INTERP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPLODCODE
	; PC 0004
	;    DB OPLOD
	;    DB 0
	;    DW (3 SHL 1) ; SHL because ints are 2 bytes long

	; get level
	LDA     TPASPC
	;find level in D, results in BASE_RET_STATIC_LINK
	SEP	GETBASE

	;subtract address
	SEX     TPASPC		; OP LOD, set X here...
	GHI     BASE_RET_STATIC_LINK
	SM
	PHI     BASE_RET_STATIC_LINK
	INC     TPASPC
	GLO     BASE_RET_STATIC_LINK
	SM     
	PLO     BASE_RET_STATIC_LINK
	INC     TPASPC

	; any borrow here because of subtract?
	BDF     LODSUB_NOCARRY
	; yes
	GHI     BASE_RET_STATIC_LINK
	SMI     1
	PHI     BASE_RET_STATIC_LINK
LODSUB_NOCARRY

	; X back to STACKREG
	SEX	STACKREG	; OP LOD, return X to default stackreg

	; BASRET says where to get it from
	LDN	BASE_RET_STATIC_LINK
	STXD
	DEC	BASE_RET_STATIC_LINK
	LDN	BASE_RET_STATIC_LINK
	STXD
	BR      INTERP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPSTOCODE
	; s [base(l) +a] := st]; writeln(s[t)); t=: t-1
	;    DB OPSTO
	;    DB 0
	;    DW (3 SHL 1) ; SHL because ints are 2 bytes long

	; get level
	LDA     TPASPC
	;find base level in D, results in BASE_RET_STATIC_LINK
	SEP	GETBASE


	;subtract address
	SEX     TPASPC		; OP STO, set X here...
	GHI     BASE_RET_STATIC_LINK
	SM
	PHI     BASE_RET_STATIC_LINK
	INC     TPASPC
	GLO     BASE_RET_STATIC_LINK
	SM     
	PLO     BASE_RET_STATIC_LINK
	INC     TPASPC

	; any borrow here because of subtract?
	BDF     STOSUB_NOCARRY
	; yes
	GHI     BASE_RET_STATIC_LINK
	SMI     1
	PHI     BASE_RET_STATIC_LINK
STOSUB_NOCARRY

	
	; X back to STACKREG
	SEX	STACKREG	; OP STO, return X to default stackreg

	; pop top of stack, and store it in TPTMP0
	INC STACKREG
	LDXA
	PLO TPTMP0
	LDX
	PHI TPTMP0

	; store it where BASE_RET_STATIC_LINK says.
	; should be in D GHI	TPTMP0
	STR	BASE_RET_STATIC_LINK
	DEC	BASE_RET_STATIC_LINK
	GLO 	TPTMP0
	STR	BASE_RET_STATIC_LINK
	BR      INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPPCALCODE
OPFCALCODE
;
; stack after the call:
;
;	---------------------------------
;	| local var...			|
;	---------------------------------
;	| local var			|
;	---------------------------------
;	|OPCODE ProgPtr Return Address	|
;	---------------------------------
;	|HL Dynam. Link	( R3 stk ptr)	|
;	---------------------------------
;	|HL Static Link			|
;	                  <---- STACKREG (stored in TPTMP1
;			  below, restored at end before
;			  br interp.
;	---------------------------------
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; save current stack pointer in TPTMP1
	; this is the "dynamic link" entry.
	GHI	STACKREG
	PHI	TPTMP1
	GLO	STACKREG
	PLO	TPTMP1


	; IGNORE get level
	;IGNORE  LDA     TPASPC
	
	; the first 3 parameters are saved on
	; the stack! The Interpreter must leave
	; these here until the return is called.

	; STATIC LINK (pointer to data frame X levels down)
	; s[tops+1] := base(lv);
	;find level in D, results in BASE_RET_STATIC_LINK
	SEP	GETBASE
	GHI	BASE_RET_STATIC_LINK
	STXD
	GLO	BASE_RET_STATIC_LINK
	STXD

	; DYNAMIC LINK (interpreter procedure "stack") 
	; s[tops+2] := dynamicLink;	
	GHI	CURFRAME_DYNAM_LINK
	STXD
	GLO	CURFRAME_DYNAM_LINK
	STXD

	; set the CURFRAME_DYNAM_LINK to the STACKREG at the start
	; of this OPCALCODE; the actual 1802 stack pointer
	; (STACKREG) will be 6 bytes "above" this at the
	; end.

	; dynamicLink  := tops+1;
	; stack at start of OPCALCODE stored in TPTMP1...
	GHI	TPTMP1
	PHI	CURFRAME_DYNAM_LINK
	GLO	TPTMP1
	PLO	CURFRAME_DYNAM_LINK



	; RETURN ADDRESS
	;get  address of procedure from the call param, and save it
	; note that this is the INTERPRETED code return address,
	; not 1802 return address.
	; p = ax;
	LDA     TPASPC
	PHI	TPTMP0
	LDA     TPASPC
	PLO	TPTMP0
	; ok, have gone through the interpreted code, got the
	; interpreted code return address, in TPTMP0.

	; TPTMP0 contains address of the procedure to call;
	; TPASPC contains the following address after the call.
	; save this address to the stack, then make TPASPC
	; equal to the address of the procedure, stored in
	; TPTMP0

	; save the return address now; this will be the 
	; instruction following this CALL.
	; s[tops+3] := p;
	GHI	TPASPC
	STXD
	GLO	TPASPC
	STXD

	; set the TPASPC to point to the called
	; procedure in the interpreted code;
	GHI	TPTMP0
	PHI	TPASPC
	GLO	TPTMP0
	PLO	TPASPC
	
	; and continue with the interpreter

	BR	INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPINTCODE
	; t=t+a;
	; shift A by 2 on conversion before here,
	; just decrement stack pointer.
	; eg, if TinyPascal OPCODE was INT 0 4
	;     make that OPINT DB 0 DW (4 SHL 1) = 8

	;IGNORE ; get level (skip past)
	;IGNORE LDA     TPASPC

	; ok to subtract (create space) on stack
	; Currently X points to STACKREG,
	; make it point to PLOPC because the number
	; subtracted points here.
	SEX	TPASPC		; OP INT, set X here...
	;JAS GHI	STACKREG
	GHI	CURFRAME_DYNAM_LINK
	SM
	PHI	STACKREG
	INC	TPASPC
	;GLO	STACKREG
	GLO	CURFRAME_DYNAM_LINK
	SM	
	PLO	STACKREG
	INC	TPASPC
	
	; any borrow here because of subtract?
	BDF	OPINTNO
	; yes
	GHI 	STACKREG
	SMI	1
	PHI	STACKREG
OPINTNO
	; X back to STACKREG
	SEX	STACKREG	; OP INT, return X to default stackreg
	
	; X points to STACKREG again
	BR      INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPJMPCODE
	; PC = A
	; but have to shift address <<2

	;IGNORE ; get level - unused
	;IGNORE LDA     TPASPC

	;get  address
	LDA     TPASPC
	PHI	TPTMP0 
	LDA     TPASPC

	; make PC point to param
	PLO	TPASPC
	GHI	TPTMP0
	PHI	TPASPC
	BR      INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPJPCCODE
	;IGNORE ; get level - not used
	;IGNORE LDA     TPASPC

	; pop the conditional
	; pop top of stack, and store it in TPTMP0
	; if 1 (or, more properly, NOT ZERO), 
        ; then the JPC is true, which just
	; means continue.
	; if 0, we do the jump
	INC STACKREG
	LDXA
	
	; OR what is in D with top of stack
	; to see if all 16 bits are 0
	; result is in D

	OR
	

	;PLO TPTMP0
	;LDX
	;PHI TPTMP0

	; do the test
	;GLO	TPTMP0

	BNZ	JPC_CONT

	;get  address and jump to it
	LDA     TPASPC
	PHI	TPTMP0
	LDA     TPASPC
	PLO	TPASPC
	GHI	TPTMP0
	PHI	TPASPC
	BR	INTERP
JPC_CONT
	; just fall through and continue at next instruction
	INC	TPASPC
	INC	TPASPC
	BR      INTERP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; page code at a page boundary.
	ORG     PAGE2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; This MUST be at a page boundary. 
;
; It implements a "jump table" so that "OPR" sub-instructions (that
; are in the range to 00H to ...H are easily "jumped" to.
; The interpreter (this program) takes the instruction,
; multiplies it by 2 (to get an address of a 2 byte space)
; then puts that in the program counter (register pointed to
; by P). The contents of this points to a "Branch to..." to
; run the specific opcode.

; OPOPRCODE jump table
;   const opr_neg_uint16 = 0;   {negative number uint16}
	LBR	OPR_NEG
	DB	0

;   const opr_plus_uint16 = 1;  {plus uint16}
	LBR	OPR_ADD
	DB	0

;   const opr_minus_uint16= 2;  {minus}
	LBR	OPR_SUB 
	DB	0

;   const opr_mul_uint16 = 3;   {multiply}
	LBR	OPR_UMUL
	DB	0

;   const opr_div_uint16 = 4;   {divide}
	LBR	OPR_UDIV
	DB	0

;   const opr_mod_uint16 = 5;   {MOD}
	LBR	OPR_UMOD
	DB	0

;   const opr_eql_uint16 = 6;   {eql}
	LBR	OPR_UEQL
	DB	0

;   const opr_neq_uint16 = 7;   {neq}
	LBR	OPR_UNEQ
	DB	0

;   const opr_lss_uint16 = 8;   {lss}
	LBR	OPR_ULSS    ; lt           EQU 00AH
	DB	0

;   const opr_geq_uint16 = 9;   {geq}
	LBR	OPR_UGEQ    ; ge           EQU 00BH
	DB	0

;   const opr_gtr_uint16 = 10;  {gtr}
	LBR	OPR_UGTR    ; gtr          EQU 00CH
	DB	0

;   const opr_leq_uint16 = 11;  {leq}
	LBR	OPR_ULEQ    ; leq          EQU 00DH
	DB	0

;   const opr_and_uint16 = 12;  {and}
	LBR	OPR_AND       ; AND          EQU 00EH
	DB	0

;   const opr_or_uint16  = 13;  {or}
	LBR	OPR_OR        ; OR           EQU 00FH
	DB	0

;   const opr_not_uint16 = 14;  {NOT}
	LBR	OPR_NOT       ; NOT          EQU 010H
	DB	0

;   {direct memory access operators}
;   const opr_peek= 15;  {peek at RAM}
	LBR	OPR_PEEK      ; PEEK         EQU 011H
	DB	0

;   const opr_poke= 16;  {poke at RAM}
	LBR	OPR_POKE      ; POKE         EQU 012H
	DB	0

;   {Set word-wide (16 bit) operators}
;   const opr_or_set16     = 17;
        ; our "or" is 16 bit compatible
	;LBR	OPR_OR_SET    ; set OR       EQU 013H
	LBR	OPR_OR        ; OR           EQU 00FH
	DB	0

;   const opr_and_set16    = 18;
        ; our "and" is 16 bit compatible
	;LBR	OPR_AND_SET   ; set AND	     EQU 014H
	LBR	OPR_AND       ; AND          EQU 00EH
	DB	0

;   const opr_dotdot_set16 = 19;       {".." operator}
	LBR	OPR_DOT_SET   ; handle dotdot EQU 015H
        DB	0

;   const opr_invert_set16 = 20;       {16 bit "not"}
	LBR	OPR_INVERT_SET
	DB	0

;   const opr_int_toSet16  = 21;       {promote enum to set for comparison}
	LBR	OPR_INT_TOSET
	DB	0

;   const opr_eql_set16    = 22;       {"=" operator}
	LBR	OPR_EQL_SET
	DB	0

;   const opr_neq_set16    = 23;       {"<>" operator}
	LBR	OPR_NEQ_SET
	DB	0

;   const opr_Lincl_set16  = 24;       {"<=" operator}
	LBR	OPR_INCL_SET
	DB	0

;   const opr_flip_tos16   = 25;       {tos := tos-1, tos-1 := tos}
	LBR	OPR_FLIP_TOS
	DB	0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPOPRCODE
	; pop top of stack, and store it in TPTMP0
	INC STACKREG
	LDXA
	PLO TPTMP0
	LDX
	PHI TPTMP0

	; go through the OPCODE, and find the operation to
	; work on the value in TPTMP0

	;get 2nd byte which is the operation
	LDA     TPASPC	; the "lv" level, pre-shifted for quick jump

	; D now contains the operation
	; pre-shifted left twice, to get the 4 byte LBR+NOP branch instruction
	; and put it into SCRTPC to do the JMP
	PLO	SCRTPC
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_VERSION	; VERSION tag bad. Does not match compiler.
OPR_NEG		; negate, but we only handle unsigned for now...

		; DOT - I don't think the compiler can parse set initializers with
		; runtime settings??
OPR_DOT_SET   ; handle dotdot EQU 015H

	; if here, something wrong
	LDI	HIGH	OP_BAD
	PHI	TPTMP1
	LDI	LOW	OP_BAD
	PLO	TPTMP1
	LBR	TX_FIN_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_INVERT_SET
        ; used in set - set
        ; TOS is in TPTMP0
        ; XOR it with itself
        ; store it on stack
        GHI     TPTMP0
        XRI	0FFH
        STXD
        GLO     TPTMP0
        XRI	0FFH
        STXD
        LBR     INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_FLIP_TOS
        ; flip the top two 16-bit words on stack
	INC	STACKREG
        LDXA    
        PLO     TPTMP1
        LDX    
        PHI     TPTMP1
        GHI     TPTMP0
        STXD
        GLO     TPTMP0
        STXD
        GHI     TPTMP1
        STXD
        GLO     TPTMP1
        STXD
        LBR     INTERP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_INT_TOSET
	; used in set - make an int (0->15) into a set
	; TOS is in TPTMP0
	LDI	HIGH	ITOSET_TABLE
	PHI	TPTMP1
	GLO	TPTMP0
	SHL
	ADI	LOW	ITOSET_TABLE
	PLO	TPTMP1

	; get the table entry
	SEX	TPTMP1
	LDXA	
	PHI	TPTMP0
	LDX	
	PLO	TPTMP0

	; push it onto stack
	SEX	STACKREG
        GHI     TPTMP0
        STXD
        GLO     TPTMP0
        STXD
        LBR     INTERP

ITOSET_TABLE
	;change int 0-> 15 into bitset.
	;0
        DB 00H
	DB 01H
	;1
	DB 00H
	DB 02H
	;2
	DB 00H
	DB 04H
	;3
	DB 00H
	DB 08H
	;4
	DB 00H
	DB 010H
	;5
	DB 00H
	DB 020H
	;6
	DB 00H
	DB 040H
	;7
	DB 00H
	DB 080H
	;8
	DB 01H
	DB 00H
        ;9
	DB 02H 
	DB 00H
	;10
	DB 04H
	DB 00H
	;11
	DB 08H
	DB 00H
	;12
	DB 010H
	DB 00H
	;13
	DB 020H
	DB 00H
	;14
	DB 040H
	DB 00H
	;15
	DB 080H
	DB 00H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; make TinyPascal code at a page boundary.
	ORG	PAGE3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_ADD
	; operation #2
	; TOS is in TPTMP0
	; SP points to 1st operand to add
	; ignore overflows here, assume uint_16
	GLO	TPTMP0
	INC	STACKREG
	ADD
	PLO	TPTMP0
	INC	STACKREG
	GHI	TPTMP0
	ADC
	PHI	TPTMP0
	; store it on stack
	GHI	TPTMP0
	STXD
	GLO	TPTMP0
	STXD
	LBR	INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_SUB
	; operation #3
	; TOS is in TPTMP0
	; SP points to 1st operand to subtract
	; ignore overflows here, assume uint_16
	GLO	TPTMP0
	INC	STACKREG
	SD
	PLO	TPTMP0
	INC	STACKREG
	GHI	TPTMP0
	; was SMB but subtract did not work >256
	SDB
	PHI	TPTMP0
	; store it on stack
	GHI	TPTMP0
	STXD
	GLO	TPTMP0
	STXD
	LBR	INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_UMUL
	; operation #4
	;printf ("multiply, x %d times y %d should be %d\n",x,y, x*y);
	;a = x; b = y; z = 0;
	;while (b > 0) {
	;  //printf ("b %d z %d a %d\n",b,z,a);
	;  if (odd(b)) {
	;    //printf ("odd b, z = %d + %d\n",z,a);
	;    z = z + a;
	;  }
	;  a = a*2; b = b/2;
	;}
	; TOS is in TPTMP0 - in the C code, this is "b"
	; SP points to 1st operand to multiply 
	; this is TPTMP1, and is "a" in the above C code.
	; result is in TPTMP0; this is "z" in the C code.

	; ignore overflows here, assume uint_16

	; get 1st operand now, and put into TPTMP1
	;a = x; b = y; z = 0;
	INC	STACKREG
	LDXA
	PLO	TPTMP1
	LDX
	PHI	TPTMP1

	; put Z on the stack for now.
	LDI	00H
	STXD
	STXD

UMULWHILE
	;while (b > 0) {
	; test lower bits first
	GLO	TPTMP0
	BNZ	UMULCONTL
	; test high bits if lower ==0
	GHI	TPTMP0
	BNZ	UMULCONTL
	
	; finished, finish up and return
	LBR	INTERP

UMULCONTH
	;  if (odd(b)) {
		GLO TPTMP0
UMULCONTL
		ANI 001H
		BZ  UMULNOTODD

		;    z = z + a;
		GLO	TPTMP1
		INC	STACKREG
		ADD
		PLO	TPTMP2
		INC	STACKREG
		GHI	TPTMP1
		ADC
		PHI	TPTMP2
		; store it on stack
		GHI	TPTMP2
		STXD
		GLO	TPTMP2
		STXD
	;  }
UMULNOTODD

	;  a = a*2; 
	GLO 	TPTMP1
	SHL	
	PLO	TPTMP1
	GHI 	TPTMP1
	SHLC	
	PHI	TPTMP1

	; b = b/2;
	GHI	TPTMP0
	SHR
	PHI	TPTMP0
	GLO	TPTMP0
	SHRC	
	PLO	TPTMP0

	;}

	; and continue muliply...
	BR	UMULWHILE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GreaterEqual  
OPR_UGEQ
	; work through high bytes
	INC	STACKREG
	INC	STACKREG
	GHI	TPTMP0
	SD
	BZ	UGEQLOW		; if 00, check lower bytes
	LDI	00H		; prep for FALSE call
	BNF	UGEQFALSE	; ULSS = BDF
	BR	UGEQ_TRUE
	; check here for LT result from high byte
UGEQLOW
	DEC	STACKREG
	GLO	TPTMP0
	SD
	INC	STACKREG
	;
	; DF=0 if LT, return 01 if DF
	BDF	UGEQ_TRUE	; ULSS = BNF
	LDI	00H
	BNF	UGEQFALSE	; ULSS = BDF
UGEQ_TRUE
	LDI	01H
UGEQFALSE
	LBR	OPR_COMMON_RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Greater than
OPR_UGTR
	; work through high bytes
	INC	STACKREG
	INC	STACKREG
	GHI	TPTMP0
	SD
	BZ	UGTRLOW		; if 00, check lower bytes
	LDI	01H		; prep for call
	BNF	UGTR_0
	BR	UGTR_1
	; check here for LT result from high byte
UGTRLOW
	DEC	STACKREG
	GLO	TPTMP0
	SD
	INC	STACKREG
	BZ	UGTR_0
	LDI	01H		; prep for TRUE call
	BNF	UGTR_0
	BR	UGTR_1
	;
UGTR_0
	LDI	00H
UGTR_1
	LBR	OPR_COMMON_RETURN


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LessthanEqual
;	TOS is in TPTMP0, 2nd argument on stack 
OPR_ULEQ
	; work through high bytes
	INC	STACKREG
	INC	STACKREG
	GHI	TPTMP0
	SD
	BZ	ULEQLOW		; if 00, check lower bytes
	LDI	00H		; prep for FALSE call
	BDF	ULEQFALSE	; ULEQ = BDF
	BR	ULEQ_TRUE
	; check here for LT result from high byte
ULEQLOW
	DEC	STACKREG
	GLO	TPTMP0
	SD
	INC	STACKREG
	;
	; DF=0 if LT, return 01 if DF
	BZ	ULEQ_TRUE
	BNF	ULEQ_TRUE	; ULEQ = BNF
	LDI	00H
	BDF	ULEQFALSE	; ULEQ = BDF
ULEQ_TRUE
	LDI	01H
ULEQFALSE
	LBR	OPR_COMMON_RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; make TinyPascal code at a page boundary.
	ORG	PAGE4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPR_UMOD
	; flag, 01 is a MOD command
	LDI	01H
	PHI	TPTMP3
	BR	UDIV_COMMON
OPR_UDIV
	; flag, 00 is a DIV command
	LDI	00H
	PHI	TPTMP3
	; BR UDIV_COMMON
	; operation #5
	;
	; BOUNDS.
	; Numerator must be <0x8000, 
	; Denominator must not be 0.
	;
	; WE can fudge numerator, by ensuring in first while, that
	; if overflow of w on the shift left, gets reset to 0xFFFF, 
	;
	;printf ("divide, x %d slash y %d should be %d\n",x,y, x/y);
	;... Numerator is "x", denominator is "y";
	;
	;r = x; w =y; q = 0;
	; if x/y, then r=numerator,w=denominator
	;
	;while (w <= r) {w = w*2;}
	;while (w > y) {
	;  q = q*2;
	;  w = w/2;
	;  if (w<=r) {
	;    r = r-w;
	;    q = q+1;
	;  }
	;printf (result in q);
	;}
	; Register/Stack usage:
	;	TPTMP0 (R0)	"w"
	;	TPTMP2 (RA)	"q"
	; Stack: (address is an example)
	; --- (FF74)	"y".l
	; --- (FF75)	"y".h	Denominator
	; --- (FF76)	"r".l
	; --- (FF77)	"r".h	Numerator 
	;
	; On entry, SP -> FF75, as the general OPR code loads
	; the first 2 bytes into TPTMP0 (R0) which is the denominator.
	; so, STACK PTR ->FF75, INC it to get to "r", DEC it to get to "y"


UDIV_COMMON
	; BOUNDS CHECK #1, is denominator "w" in TPTMP0
	; not zero?
	GHI	TPTMP0		;w.h 
	LBNZ	UDIV_BC1
	GLO	TPTMP0		;w.l
	LBNZ	UDIV_BC1
	
	; Denominator is 0.
	; BOUNDS CHECK FAIL
	; if here, something wrong - divide by zero
	LDI	HIGH	DIV_BY_ZERO
	PHI	TPTMP1
	LDI	LOW	DIV_BY_ZERO
	PLO	TPTMP1
	LBR	TX_FIN_LOOP

	; past the bounds check, lets do it!
UDIV_BC1
	; zero "q"
	LDI	00H
	PLO	TPTMP2		;q.l
	PHI	TPTMP2		;q.h

	; Point to the numerator ("r") now
	INC	STACKREG	;SP -> FF76
	INC	STACKREG	;SP -> FF77
	;

	; R2 (stack) points to high byte of r value, Stack-1
	; points to low byte. 
	; Manipulate "w" but keep "y" in memory for second
	;-----------------------------------------------------
	; first while loop in UDIV
UDIV_WHILE1
		; while (w <= r) {w = w*2}
		; "r" is on the stack, "w" in TPTMP0

		; upper byte first
		; SP -> FF77, r.h
		;--------------------------------------------
		; do we continue, or test lower bits or exit?
		; "w" "r"
		; D   R(x)	SD		SM
		; 4 < 5		DF 1 D 01	DF 0 D FF
		; 5 = 5		DF 1 D 00	DF 1 D 00
		; 6 > 5		DF 0 D FF	DF 1 D 01
		;--------------------------------------------

		GHI	TPTMP0		; w.h
		SD			; 

		; from table above if w 
		BNF	UDIV_WHILE2	; if w.h > r.h, go to while2
		BNZ	UDIV_WHILE1_LOOP; if w.h < r.h, continue

		; but if w.h = r.h, check lower bits
		DEC	STACKREG	; point now to r.l
					; SP -> FF76
		GLO	TPTMP0		; w.l
		SD			; 
		INC	STACKREG	; SP -> FF77
		BNF	UDIV_WHILE2	; we are less...

		; if DF is set, we are still >=
		; ok, continue the loop.
UDIV_WHILE1_LOOP
		; {w = w*2}
		; SHL "w", which is in TPTMP0
		GLO	TPTMP0
		SHL
		PLO	TPTMP0
		GHI	TPTMP0
		SHLC
		PHI	TPTMP0

		BNF	UDIV_WHILE1
		; is this an overflow of TPTMP0? if so,
		; mark this and die.
    	    	; BOUNDS CHECK FAIL
       	 	; if here, something wrong
		LDI	HIGH	DIV_OVERFLOW
		PHI	TPTMP1
		LDI	LOW	DIV_OVERFLOW
		PLO	TPTMP1
		LBR	TX_FIN_LOOP
		; 
		; ok, upper bite is giving us good signs...
		; do we need to test lower bits?

	;-----------------------------------------------------
	; second while loop in UDIV
	; SP -> FF77	; r.h

UDIV_WHILE2

	; Y is untouched on the stack, but we have to decrement 
	; to get to it
	DEC	STACKREG	; SP -> FF76 ;r.l
	DEC	STACKREG	; SP -> FF75 ;y.h
UDIV_W2_LOOP
	;while (w > y) {
		; Y is on the stack, W is TPTMP0
		; currently, SP -> FF75 ; y.h
		GHI	TPTMP0
		SD
		; high bits; is this greater than?
		BNF	W2_CONT

		; no, the subtract is 00H,check the lower 8 bits.
		DEC	STACKREG ; SP -> FF74; y.l
		GLO 	TPTMP0
		SD
		INC	STACKREG ; SP -> FF75; y.h
		BNF	W2_CONT	

		BR	UDIV_W2_FIN
W2_CONT
		; ok, do the contents of the 2nd while loop here.

		;  q = q*2;
		GLO 	TPTMP2
		SHL	
		PLO	TPTMP2
		GHI 	TPTMP2
		SHLC	
		PHI	TPTMP2

       	 	;  w = w/2;
		GHI	TPTMP0
		SHR
		PHI	TPTMP0
		GLO	TPTMP0
		SHRC	
		PLO	TPTMP0

		;  if (w<=r) {
			;  w is in TPTMP0
			;  r is on stack
			; get stack back to pointing to "r"
			INC	STACKREG ; SP -> FF76, r.l
			INC	STACKREG ; SP -> FF77, r.h

			; stack now points to "r".h
			GHI	TPTMP0	; "w"
			SD
			DEC	STACKREG ; SP -> FF76, r.l
			DEC	STACKREG ; SP -> FF75, y.h

			BNF	UDIV_W2_LOOP
			BNZ	DO_THIS_IF
			; 
			; check lower bits
			INC	STACKREG ; sp -> FF76, r.l
			GLO	TPTMP0
			SD
			DEC	STACKREG ; sp -> FF75, y.h
			BNF	UDIV_W2_LOOP
DO_THIS_IF 
		;  
		;    r = r-w;
			;  w is in TPTMP0
			;  r is on stack at FEF6 (L)  FEF7 (H)
			; get stack back to pointing to "r"
			INC	STACKREG ; sp -> FF76, r.l
			; stack now points to "r".l
			GLO	TPTMP0	; w.l
			SD
			PLO	TPTMP1

			INC	STACKREG ; sp -> FF77, r.h
			GHI	TPTMP0	; w.h
			SDB
			PHI	TPTMP1

			; store new value of r on stack
			STXD
			GLO	TPTMP1
			STXD
			; sp -> FF75, y.h


		;    q = q+1;
			GLO 	TPTMP2	; q.l
			ADI	001H	
			PLO	TPTMP2	; q.l
			
			; add only if q.l overflows
			BNF	UDIV_W2_LOOP ;SKIP_UDWH_ADD
			GHI 	TPTMP2	; q.h
			ADI	001H
			PHI	TPTMP2	;q.h
;SKIP_UDWH_ADD; can just do a BR UDIV_W2_LOOP
		;  }
		
	BR	UDIV_W2_LOOP

	;  }
UDIV_W2_FIN
	; is this a MOD (01 in flag) or DIV (00 in flag)
	; MOD returns "r" which is in TPTMP1
	; DIV returns "q" which is in TPTMP2

	GHI	TPTMP3
	BZ	UDIV_IS_DIV

	; put the stack where it was, before the OP intro
	;INC	STACKREG	; SP -> FF76
	;INC	STACKREG	; SP -> FF77


	;GHI	TPTMP1
	;STXD
	;GLO	TPTMP1
	;STXD
	LBR	INTERP	

UDIV_IS_DIV
	; put the stack where it was, before the OP intro
	INC	STACKREG	; SP -> FF76
	INC	STACKREG	; SP -> FF77
	GHI	TPTMP2
	STXD
	GLO	TPTMP2
	STXD

	LBR	INTERP






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Less than 
;	TOS is in TPTMP0, 2nd argument on stack 
;	e.g. (11 < 10)
OPR_ULSS
	; work through high bytes
	INC	STACKREG
	INC	STACKREG
	GHI	TPTMP0
	SD
	BZ	ULSSLOW		; if 00, check lower bytes
	LDI	00H		; prep for FALSE call
	BDF	UTLFALSE
	BR	UTL_TRUE
	; check here for LT result from high byte
ULSSLOW
	DEC	STACKREG
	GLO	TPTMP0
	SD
	INC	STACKREG
	;
	; DF=0 if LT, return 01 if DF
	BNF	UTL_TRUE
	LDI	00H
	BDF	UTLFALSE
UTL_TRUE
	LDI	01H
UTLFALSE

OPR_COMMON_RETURN
	STXD	
	STXD
	LBR	INTERP



; make TinyPascal code at a page boundary.
	ORG	PAGE5	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Equal
;	TOS is in TPTMP0, 2nd argument on stack 
OPR_EQL_SET
OPR_UEQL
	; work through high bytes
	INC	STACKREG
	INC	STACKREG
	GHI	TPTMP0
	SD
	BZ	UEQLLOW		; if 00, check lower bytes
	LDI	00H		; prep for FALSE call
	BR	UEQL_END
	; check here for LT result from high byte
UEQLLOW
	DEC	STACKREG
	GLO	TPTMP0
	SD
	INC	STACKREG
	;
	BZ	UEQL_TRUE
	LDI	00H
	BR	UEQL_END
UEQL_TRUE
	LDI	01H
UEQL_END
	LBR	OPR_COMMON_RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NOT Equal
;	TOS is in TPTMP0, 2nd argument on stack 
OPR_UNEQ
OPR_NEQ_SET
	; work through high bytes
	INC	STACKREG
	INC	STACKREG
	GHI	TPTMP0
	SD
	BZ	UNEQLOW		; if 00, check lower bytes
	LDI	01H		; prep for TRUE call
	BR	UNEQ_END
	; check here for LT result from high byte
UNEQLOW
	DEC	STACKREG
	GLO	TPTMP0
	SD
	INC	STACKREG
	;
	BNZ	UNEQ_TRUE
	LDI	00H
	BR	UNEQ_END
UNEQ_TRUE
	LDI	01H
UNEQ_END
	LBR	OPR_COMMON_RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; AND
;
;	this is a boolean AND, but we make it into a 
;	16 bit boolean and - for when we support bools.
;	
;	We may NEVER support full 16 bit bools, but if we
;	do, we are prepared!

OPR_AND
	INC	STACKREG
	GLO	TPTMP0
	AND
	PLO	TPTMP0
	; work through high bytes
	INC	STACKREG
	GHI	TPTMP0
	AND
	PHI	TPTMP0

	GHI	TPTMP0
	STXD	
	GLO	TPTMP0
	STXD
	LBR	INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OR
;	this is a boolean OR, but we make it into a 
;	16 bit boolean and - for when we support bools.
;	
;	We may NEVER support full 16 bit bools, but if we
;	do, we are prepared!
OPR_OR
	INC	STACKREG
	GLO	TPTMP0
	OR
	PLO	TPTMP0
	; work through high bytes
	INC	STACKREG
	GHI	TPTMP0
	OR
	PHI	TPTMP0

	GHI	TPTMP0
	STXD	
	GLO	TPTMP0
	STXD
	LBR	INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NOT
;	TOS is in TPTMP0, 2nd argument on stack 
OPR_NOT
	; work through high bytes
	INC	STACKREG
	INC	STACKREG
; this is crap, from the UNEQ code, needs changing for UNOT
	GHI	TPTMP0
	SD
	BZ	UNOTLOW		; if 00, check lower bytes
	LDI	01H		; prep for TRUE call
	BR	UNOT_END
	; check here for LT result from high byte
UNOTLOW
	DEC	STACKREG
	GLO	TPTMP0
	SD
	INC	STACKREG
	;
	BNZ	UNOT_TRUE
	LDI	00H
	BR	UNOT_END
UNOT_TRUE
	LDI	01H
UNOT_END
	LBR	OPR_COMMON_RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SET Inclusion
; this is a combination of AND and equals; 
; first we see if we AND the bits in the desired
; set and the main set; this is to get an intersection
; set. Then, to do the condition, we AND this result
; with the initial desired set, and the
; result is put on the stack for a JPC or equiv.
OPR_INCL_SET

	; ok, TPTMP0 contains the TOS, which is the set.
	; on the stack still is the variable we want to see
	; if it is in the set.
	; from test, where container set has 
	;   0x00FF
	; and the variable we want to see if it is in,
	;   0x0002 
	
;STK +2 here (initialization code common ->TPTMP0)

	; step 1 is like an OPR_AND
        INC     STACKREG
;STK +3
        GLO     TPTMP0	; the full set container value
        AND		; R(x) points here
        PLO     TPTMP0	; result of and low byte 

        ; work through high bytes
        INC     STACKREG
;STK +4
        GHI     TPTMP0	; full set container value
        AND
        PHI     TPTMP0	; result of and high bite

	; in our test, TPTMP1 should return 0x0002,
	; because 0002 (on the stack) and 00FF (in TPTMP0,
	; popped from the stack) returns 0002.

	; ok for the AND step to see if all bits of our
	; test variable fit in the set container, we move
	; this AND over to TPTMP0, and AND this with
	; what is on the stack still - the untouched
	; variable.
	;
	; To do this, we take the result (TPTMP1)
	; and move it to TPTMP0, then jump into the
	; EQL code, bypassing the initialization pop
	; that all OPRs do.
	
	; "push" the result, so we have STK+2, then jump into
	; the middle of the EQL code; TPTMP0 will contain the
	; results of the set intersection, and we test with
	; an AND to see if the intersection is the required 
	; contents. 

	DEC	STACKREG
	DEC	STACKREG
;STK +2

	; NOW we check for equality between this 
	; intersection result with orig val.
	;
	; jumping directly into the EQL code, there is 
	; some common setup we can skip.
	;
	; simulate getting the stack that happens at the
	; beginning or OPOPRCODE
	; pop top of stack, and store it in TPTMP0
	; OPOPRCODE:	INC STACKREG
	; OPOPRCODE:	LDXA
	; OPOPRCODE:	PLO TPTMP0
	; OPOPRCODE:	LDX
	; OPOPRCODE:	PHI TPTMP0
	;
	; now, just branch to OPR_EQL_SET, the result
	; of the first AND is stored in the stack,
	; the second one is prepped with TPTMPO having
	; the original.

	LBR OPR_EQL_SET



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PEEK
;	TOS is in TPTMP0, it contains the address
;	to peek
OPR_PEEK
	; get the data this points to
	SEX	TPTMP0
	LDX
	PLO	TPTMP1
	SEX	STACKREG
	
	; upper byte
	LDI	00H
	STXD

	; lower byte
	GLO	TPTMP1
	STXD
	LBR	INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; POKE
;	TOS is in TPTMP0, it contains the data (low byte)
;	2nd argument (locn to poke) on stack 
OPR_POKE
	; pop the destination address, store the lower byte
	; TPTMP0 points to

	
	INC	STACKREG
	LDXA
	PLO	TPTMP1
	LDX
	PHI	TPTMP1

	; TPTMP1 now contains the address

	GLO	TPTMP0
	STR	TPTMP1

	LBR	INTERP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Text output. (uint16, char strings)
;
; first byte shows what type of data it is;
; if 0, a newline;
; if 1, a text string, and pointer to data follows,
; if 2, a uint16, stored on the stack.
; if 3, an ascii character.
;
;        const IO_newLine = 0; {not a valid table entry, so we just use this}
;        const IO_charString = 1 {charStringType};
;        const IO_uint16 = 2 {uint16Type};
;        const IO_char = 3 {charType};


 
OPTXOUT
	LDA	TPASPC		; IO_newline (0) not generated.
	SMI	1
	BZ	TX_CHARSTRING	; matches IO_charString (1)
	SMI	1
	BZ	TX_UINT16	; matches IO_uint16 (2)
	SMI	1
	BZ	TX_CHAR		; matches IO_char (3)

				; nope, an error in data type
	LDA	TPASPC
	LDA	TPASPC
	LDI	HIGH	TYPE_NOT_SUPPORTED
	PHI	TPTMP1
	LDI	LOW	TYPE_NOT_SUPPORTED
	PLO	TPTMP1
	LBR	TX_FIN_LOOP


TX_UINT16
	; Value is on the stack.
	; the "address" field is meaningless here, so skip
	LDA	TPASPC
	LDA	TPASPC

	; pop top of stack, and store it in TPTMP0
	INC STACKREG
	LDXA
	PLO TPTMP0
	LDX
	PHI TPTMP0
	LBR	PRINT_UINT16

TX_CHAR
	; Value is on the stack.
	; the "address" field is meaningless here, so skip
	LDA	TPASPC
	LDA	TPASPC

	; pop top of stack, and store it in TPTMP0
	INC STACKREG
	LDXA
	PLO DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN
	; ensure X is set to stackreg 
	; probably not needed??
	SEX	STACKREG
	LBR	INTERP

TX_CHARSTRING
	; Value is NOT on the stack, AX points to string in memory.
	; "AX" is the 16 bit pointer to the string, ends in NULL
	LDA	TPASPC
	PHI	TPTMP1
	LDA	TPASPC
	PLO	TPTMP1
TX_LOOP
	SEX	TPTMP1		; TX_LOOP, Set X here to point to string
	LDXA
	SEX	STACKREG	; TX_LOOP, return X to default STACKREG
	LBZ	INTERP		; done, got the null at end of string
	PLO	DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN
	; ensure X is set to stackreg 
	BR	TX_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; make code at a page boundary.
	ORG	PAGE6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; version check code.
OPVERCODE
	; TinyPascal compiler puts version via a lod literal,
	; so the version is on the stack. Check what we have
	; hard-coded in MY_VERSION.
	; note that the "stack" data is put in TPTMP0 already.

	; IGNORE ; get level - ignore this
	; IGNORE LDA     TPASPC
	;get  address
	; push high byte then low byte, eg DW 020H push 00 then 20
	LDA     TPASPC
	PHI	TPTMP0
	LDA     TPASPC
	PLO	TPTMP0

	GHI	TPTMP0
	SDI	HIGH MY_VERSION
	BNZ	BAD_VERSION
	GLO	TPTMP0
	SDI	LOW MY_VERSION
	BNZ	BAD_VERSION
	; version is ok, continue
	LBR	INTERP

BAD_VERSION
	; if here, version wrong
	LDI	HIGH	VERSION_BAD
	PHI	TPTMP1
	LDI	LOW	VERSION_BAD
	PLO	TPTMP1
	LBR	TX_FIN_LOOP
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPXITCODE

; print out PROGRAM_FINISH

	LDI	HIGH	PROGRAM_FINISH
	PHI	TPTMP1
	LDI	LOW	PROGRAM_FINISH
	PLO	TPTMP1
TX_FIN_LOOP
	SEX	TPTMP1	; OPXIT, set X,
	LDXA
	SEX	TPTMP1	; OPXIT, set back to default
	LBZ	COLD_START		; done, got the null at end of string
	PLO	DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN
	LBR	TX_FIN_LOOP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPSTKCODE
	;    stk: 
	;         case lv of {increment or decrement}
	;             
	;        0: begin {decrement stack to remove procedure params
	;              that were placed where the proc/func body expects them}
	;            tops := tops-ax;
	;            end;
	;        1: begin {increment stack to allow for procedure params
	;              to be placed where the proc/func body expects them}
	;            tops := tops+ax;
	;            end;
	;         end;
	;    t := t+1; s[t] = a

	; get the "level" - it is used to determine which 
	LDA	TPASPC
	SEX	TPASPC
	BZ	OPSTKDEC

	;        1: begin {increment stack to allow for procedure params
	;              to be placed where the proc/func body expects them}
	;            tops := tops+ax;
	;            end;
	; stack goes down, so we decrement stack pointer to "increase" stack
        ; skip to 2nd byte of the "address" field.
	INC	TPASPC
	GLO	STACKREG
	SM
	PLO	STACKREG

        ; go back to the first byte - the high byte, subtract with borrow
	DEC	TPASPC
	GHI	STACKREG
	SMB
	PHI	STACKREG

        ; go forward past BOTH bytes, and continue with new stack pointer.
	INC	TPASPC
	INC	TPASPC

	SEX	STACKREG	; X ALWAYS defaults to STACKREG
	LBR	INTERP
OPSTKDEC
	;        0: begin {decrement stack to remove procedure params
	;              that were placed where the proc/func body expects them}
	;            tops := tops-ax;
	;            end;
	; same as code for option "1" above, but with add instead of subtract
	INC	TPASPC
	GLO	STACKREG
	ADD
	PLO	STACKREG
	DEC	TPASPC
	GHI	STACKREG
	ADC
	PHI	STACKREG
	INC	TPASPC
	INC	TPASPC
	SEX	STACKREG	; X ALWAYS defaults to STACKREG
	LBR	INTERP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NOT IMPLEMENTED YET
OPTXIN
        ;    t := t+1; s[t] = a
	; call the SCRT input routine; char in RB.0 on return.
	LDI	00H
        STXD
	SEP	SCRTCALL
	DW	CHAR_IN_MAIN
	GLO	DATAREG	; character here
        STXD
	LBR	INTERP





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; print out a uint_16 that is on the stack.

PRINT_UINT16
	; high high nibble
	GHI TPTMP0
	ANI	0F0H
	SHR
	SHR
	SHR
	SHR
	PLO	BASE_RET_STATIC_LINK
	SMI	00AH
	GLO	BASE_RET_STATIC_LINK
	BDF	EX0
	ADI	'0'
	BR	EX1
EX0
	GLO	BASE_RET_STATIC_LINK
	ADI	'A'-10
EX1
	PLO	DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN

	; high low nibble
	GHI TPTMP0
	ANI	00FH
	PLO	BASE_RET_STATIC_LINK
	SMI	00AH
	GLO	BASE_RET_STATIC_LINK
	BDF	EX2
	ADI	'0'
	BR 	EX3
EX2
	GLO	BASE_RET_STATIC_LINK
	ADI	'A'-10
EX3
	PLO	DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN
	
;----
	; low high nibble
	GLO TPTMP0
	ANI	0F0H
	SHR
	SHR
	SHR
	SHR
	PLO	BASE_RET_STATIC_LINK
	SMI	00AH
	GLO	BASE_RET_STATIC_LINK
	BDF	EX00
	ADI	'0'
	BR	EX10
EX00
	GLO	BASE_RET_STATIC_LINK
	ADI	'A'-10
EX10
	PLO	DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN

	; low low nibble
	GLO TPTMP0
	ANI	00FH
	PLO	BASE_RET_STATIC_LINK
	SMI	00AH
	GLO	BASE_RET_STATIC_LINK
	BDF	EX20
	ADI	'0'
	BR 	EX30
EX20
	GLO	BASE_RET_STATIC_LINK
	ADI	'A'-10
EX30
	PLO	DATAREG
	SEP	SCRTCALL
	DW	CHAR_OUT_MAIN
	
	LBR INTERP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;      ret: begin
OPFRETCODE
	; function sets flag to 01
	LDI	01
	BR	OPRCONT
OPPRETCODE
	; procedure sets flag to 00
	LDI	00
OPRCONT

	PHI	TPTMP3
	;             if lv=1 then
	;               begin
	;                 {write ('returning a function value... dynamicLink:',dynamicLink:3);}
	;                 rv := s[dynamiclink+3];
	;                 {writeln (tops:5,' value:',rv:3);}
	;                 tops := dynamicLink - 1; 
	;                 progPtr := s[tops + 3]; 
	;                 dynamicLink := s[tops + 2];
	;
	;                 tops := tops+1;
	;                 s[tops] := rv;
	;                 {writeln('ret 1, tos is:',tops:2);}
	;                 
	;               end
	;             else 
	;               begin
	;                 {normal procedure return}
	;                 tops := dynamicLink - 1; 
	;                 progPtr := s[tops + 3]; 
	;                 dynamicLink := s[tops + 2];
	;               end;
	;           end;
	
	; The current frame is stored in CURFRAME_DYNAM_LINK, (R1).
	; We don't keep track of how many local variables
	; we have on the stack, so for return, we reference
	; the CURFRAME_DYNAM_LINK to give us:
	; [0,1] STATIC LINK to FRAME of caller (SP after the "return")
	; [2,3] CURFRAME_DYNAM_LINK DynamicLink base, i.e. TOS of caller
	; [4,5] RETURN interpreter address. (address of next pcode instr)
	;
	; On entry, X-2 -> the stack pointer.
	
	SEX	CURFRAME_DYNAM_LINK

	; Stack pointer for after return, it is the CURFRAME_DYNAMIC_LINK
	; so, make it so. 
	GHI	CURFRAME_DYNAM_LINK
	PHI	STACKREG
	GLO	CURFRAME_DYNAM_LINK
	PLO	STACKREG

	; go and get the "dynamic link" which is the frame
	; of the caller. 
	; which we have stored here in THIS frame.

	LDX
	PHI	BASE_RET_STATIC_LINK
	DEC	CURFRAME_DYNAM_LINK
	LDX
	PLO	BASE_RET_STATIC_LINK
	DEC	CURFRAME_DYNAM_LINK

	; [2,3] frame (stack position) of caller
	LDX
	PHI	TPTMP1
	DEC	CURFRAME_DYNAM_LINK
	LDX
	PLO	TPTMP1
	DEC	CURFRAME_DYNAM_LINK

	; now, PLTMP0 contains the base frame of the caller.
	 
	; get the return address.
	; [4,5] caller address.
	LDX	
	PHI	TPASPC
	DEC	CURFRAME_DYNAM_LINK
	LDX
	PLO	TPASPC
	
	; is this a function? if so:
	; [6,7] is the return value; store it in TPTMP0
	GHI	TPTMP3
	BZ	RET_SKIP_GET_RV
	DEC	CURFRAME_DYNAM_LINK
	LDX
	PHI	TPTMP0
	DEC	CURFRAME_DYNAM_LINK
	LDX
	PLO	TPTMP0
RET_SKIP_GET_RV

	; now, make "curframe" point to callers;
	GHI	TPTMP1
	PHI	CURFRAME_DYNAM_LINK
	GLO	TPTMP1
	PLO	CURFRAME_DYNAM_LINK

	; put X back to STACKREG
	SEX	STACKREG

	; is this a procedure or function?
	; if a procedure, go to next pcode instruction
	; if not, push fn results onto stack, then cont.
	GHI	TPTMP3
	LBZ	INTERP

	; this is a function, get return value, and
	; push it on the stack.
	GHI	TPTMP0
	STXD
	GLO	TPTMP0
	STXD
	LBR	INTERP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Interpreter base function
; 
; input - level in D (8-bit)
; output - absolute address of variable on stack, reg BASE_RET_STATIC_LINK
;YYY 
; function base(L: integer): integer; var b1: integer;
;   begin b1 := b; {find base L levels down} 
;     while L > 0 do
;       begin b1 := s[b1]; L := L-1
;   end; 
;   base := bl
; end {base}

BASE_RT:
	; X back to STACKREG
	SEX     STACKREG	; BASE function, set X back to default
	;return base
	SEP SCRTPC

BASEFUNC:
	; level is in D store it in TMP0 for now.
	PLO	TPTMP0
	
	; get the current "top" frame:
	GHI	CURFRAME_DYNAM_LINK
	PHI	BASE_RET_STATIC_LINK
	GLO	CURFRAME_DYNAM_LINK
	PLO	BASE_RET_STATIC_LINK



BASELOOPDOWN:
	; get the correct level "down"
	; trying to figure Emma02 out GLO	TPTMP0
	GLO	TPTMP0
	BZ	BASE_RT
	; go to a frame lower
	DEC	TPTMP0

	; BASE_RET_STATIC_LINK [0,1] contains the address of the previous frame,
	; stored when executing the "CAL" opcode. Get this, and,
	; keep going until level (TPTMP0) is 0.	
	; BASE_RET_STATIC_LINK will point to start of the 16 bit "lower" address.
	; eg, current BASE_RET_STATIC_LINK is FEF7.
	; eg, FEFF for the next lower frame is stored as
	; FEF7: FE
	; FEF6: FF
 
	SEX	BASE_RET_STATIC_LINK	; BASE function, set X to our use
	LDX	; in example, returns FE, the high byte of address
	PHI	TPTMP0	; store temporary.. in the example above, FE
	DEC	BASE_RET_STATIC_LINK
	LDX	; in example, returns FF, the low byte of the address
	PLO	BASE_RET_STATIC_LINK

	GHI	TPTMP0  ; retrieve temporary...
	PHI	BASE_RET_STATIC_LINK
	BR	BASELOOPDOWN

	END
