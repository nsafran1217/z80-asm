

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; OUTPUT VALUE OF A IN HEX ONE NYBBLE AT A TIME
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
hexout:
    	PUSH BC
		PUSH AF
		LD B, A
		; Upper nybble
		SRL A
		SRL A
		SRL A
		SRL A
		CALL TOHEX


        CALL OutputChar

		
		; Lower nybble
		LD A, B
		AND 0FH
		CALL TOHEX


		CALL OutputChar

		
		POP AF
		POP BC
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; TRANSLATE value in lower A TO 2 HEX CHAR CODES FOR DISPLAY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
TOHEX:
		PUSH HL
		PUSH DE
		LD D, 0
		LD E, A
		LD HL, DATA
		ADD HL, DE
		LD A, (HL)
		POP DE
		POP HL
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CheckIfHex
;   Check and convert an ascii code to 4-bit hex value
;
;   input:      A --- ascii character   
;   return:     A --- 0x00 - 0x0f 
;               CF  --- error 
;   destroyed:  

CheckIfHex:
	CP "0"			;If its less than ASCII 0
	JP C, NotHex
	CP "A"			;If its A or higher
	JP NC, LetterHex
	SUB "0"			;Otherwise, just subtract $30 and ret
	RET
LetterHex:
	CALL ToUpper
	CP "A"			;If its less than A
	JP C, NotHex
	CP "G"
	JP NC, NotHex
	SUB  $37		;Substract $37 from A thru F
	RET
NotHex:  
	SUB $FF			;Set the carry flag
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 	ASCII char code for 0-9,A-F in A to single hex digit
;;    subtract $30, if result > 9 then subtract $7 more
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ATOHEX:
		SUB $30
		CP 10
		RET M		; If result negative it was 0-9 so we're done
		SUB $7		; otherwise, subtract $7 more to get to $0A-$0F
		RET		

	
DATA:
		DEFB	30h	; 0
		DEFB	31h	; 1
		DEFB	32h	; 2
		DEFB	33h	; 3
		DEFB	34h	; 4
		DEFB	35h	; 5
		DEFB	36h	; 6
		DEFB	37h	; 7
		DEFB	38h	; 8
		DEFB	39h	; 9
		DEFB	41h	; A
		DEFB	42h	; B
		DEFB	43h	; C
		DEFB	44h	; D
		DEFB	45h	; E
		DEFB	46h	; F
