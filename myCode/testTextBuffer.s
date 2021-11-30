DIVISOR = $0C
UART = $00
UARTLSR = $05   
RAMSTART = $5000 
DATALEN = $1000 ;4k bytes
COMMANDSTRING = RAMSTART + DATALEN - $100



    .org $4000

Start:
    LD SP,$ffff
    LD IY,TestLoadMsg
    CALL PrintStr
    JP CommandPrompt
PrintStr: ;Print a string indexed in IY
        PUSH AF
PrintStrLoop
        LD A,(IY)               ;LD into A value at address in IY
        CALL OutputChar         ;Output A
        INC IY                  ;INC IY, which is incrementing the address of the message
        LD A,(IY)               ;LD into A the next char to be printed
        CP $00                  ;Check if that char is 0. CP subtracts value from A but doesnt chnage A, only updates flags
        JP NZ,PrintStrLoop          ;If its not 0, go back to Alert and continue printing
        POP AF
        RET
        
NewLine:
        LD IY,CRLF
        CALL PrintStr
        RET

HelpCMD:
    LD IY, HelpMSG
    CALL PrintStr
    JP CommandPrompt
ReadCMD:

WriteCMD:

BeepCMD:
    LD A, $07                   ;Bell character
    CALL OutputChar
    JP CommandPrompt

CommandPrompt:  
        LD A, ':'
        CALL OutputChar
        LD HL,COMMANDSTRING     ;Location of string, length prefixed
        LD (HL),0               ;Number of characters counter   
        INC HL         
CommandPromptLoop:

        CALL Input              ;Wait for user Input
        CALL OutputChar         ;Echo char
        CP $0D                  ;CR
        JP Z, CommandParse      ;If CR, go to command parse
        CP $08                  ;If BS, go to backspace
        JP Z, BackSpace               
        LD (HL), A              ;Else put char in memory
        INC HL
        PUSH HL
        LD HL,COMMANDSTRING     ;INC counter of characters
        INC (HL)
        POP HL


        JP CommandPromptLoop


CommandParse:
    CALL NewLine
    LD A, (COMMANDSTRING)
    CP $00                  ;If not chars in counter
    JP Z, CommandPrompt     ;Go Back to prompt

    LD DE,00                ;Number of the command we are testing, though each command is 2 numbers. 1st is 0, 2nd is 2, 3rd is 4, 4th is 6, etc...

CommandParseLoop:
    LD HL,Commands          ; put into HL location of command locations
    ADD HL, DE              ; inc HL to command we are testing
    PUSH HL                 ;Store HL
    LD A, (HL)              ;LD A with value at HL
    CP $00                  ;Check if 0
    JP NZ, ContinueParse    ;If not, keep going
    INC HL                  ;need to check other nybble
    LD A, (HL)          
    CP $00
    JP NZ, ContinueParse    
    POP HL                  ;If this nybble is also zero, pop HL(Cleanup stack)
    JP InvalidCommand       ;JP

ContinueParse:
    POP HL
    PUSH DE                 ;store number command we are testing
    LD E, (HL)              ; put high nybble into E from address of command
    INC HL                  ;to low nybble
    LD D, (HL)              ;ld low nybble
    LD HL, COMMANDSTRING    ;put command to compare addr in hl
    CALL CmpStrings
    POP DE                  ;Get num of command we are testing

    JP Z, CommandMatch      ;If strings match, jump
    INC DE                  ; inc de to next number command to test
    INC DE
    JP CommandParseLoop     ;and do it again
    
 
    
CommandEcho:    
    LD HL,COMMANDSTRING     ;ld address of command
    LD D, (HL)              ;load length of string into d
    INC HL                  ; inc to first char

CommandEchoLoop:
    LD A,(HL)               ;ld first char
    CALL OutputChar         ;output it
    INC HL                  ;next char
    DEC D                   ;dec number of chars left to print
    LD A,D                  ;see if num of chars is 0
    CP $00
    JP NZ, CommandEchoLoop  ;if not zero, loop
    CALL NewLine            ;else, print new line
    JP CommandPrompt

;;command number should be in DE [E] at this point
CommandMatch:   ;;for testing
    LD A, 'O'
    CALL OutputChar
    LD A, 'k'
    CALL OutputChar
    CALL NewLine
    LD A,E                  ;Put num of command in A
    JP CommandExecute
    ;JP CommandEcho

InvalidCommand:
    LD IY,InvalidCommandMSG
    CALL PrintStr
    JP CommandEcho
;;Command number to execute is in A
CommandExecute:
    CALL hexout
    CP $00
    JP Z, HelpCMD
    CP $02
    JP Z, ReadCMD
    CP $04
    JP Z, WriteCMD
    CP $06
    JP Z, BeepCMD
    JP CommandPrompt


BackSpace:
    PUSH HL
    LD HL,COMMANDSTRING
    ;LD D, (HL)
    LD A,(HL)
    CP $00                  ;If chars in counter
    JP NZ, DelChar          ;Jump to DelChar
    LD A, $1B               ;ANSI Escape
    CALL OutputChar
    LD A, '['
    CALL OutputChar
    LD A, 'C'               ;Erase Line
    CALL OutputChar
    POP HL
    JP CommandPromptLoop
DelChar:
    PUSH HL
    LD HL, COMMANDSTRING
    DEC (HL)                ;get rid of the last char in buffer

    LD A, $1B               ;ANSI Escape
    CALL OutputChar
    LD A, '['
    CALL OutputChar
    LD A, 'K'               ;Erase Line
    CALL OutputChar
    POP HL
    DEC HL
    JP CommandPromptLoop


;IN    HL     Address of string1.
;      DE     Address of string2.
;OUT   zero   Set if string1 = string2, reset if string1 != string2.
;      carry  Set if string1 > string2, reset if string1 <= string2.
;from https://tutorials.eeems.ca/ASMin28Days/lesson/day16.html#cmp
CmpStrings:
    PUSH   HL
    PUSH   DE

    LD     A, (DE)          ; Compare lengths to determine smaller string
    CP     (HL)            ; (want to minimize work).
    JR     C, Str1IsBigger
    LD     A, (HL)

Str1IsBigger:
    LD     C, A             ; Put length in BC
    LD     B, 0
    INC    DE              ; Increment pointers to meat of string.
    INC    HL

CmpLoop:
    LD     A, (DE)          ; Compare bytes.
    CPI
    JR     NZ, NoMatch      ; If (HL) != (DE), abort.
    INC    DE              ; Update pointer.
    JP     PE, CmpLoop

    POP    DE
    POP    HL
    LD     A, (DE)          ; Check string lengths to see if really equal.
    CP     (HL)
    RET

NoMatch:
    DEC    HL
    CP     (HL)            ; Compare again to affect carry.
    POP    DE
    POP    HL
    RET

Oth


;; Take a character in register A and output to the UART, 
OutputChar:
        OUT (UART),A		; Send character to UART
        PUSH AF
LoopOut:			; Ensure the byte was transmitted
        IN A,(UARTLSR)          ; Read LSR
        BIT 6,A                 ; Check bit 6 (THR empty, line idle)
        JP Z,LoopOut
        POP AF                  ;bring back our registers

        RET

;; Read a character from the UART and place in register A
Input:
	IN A,(UARTLSR)		  ; Read LSR
	BIT 0,A			  ; Check bit 0 (RHR byte ready)
	JP Z,Input                ; If zero, keep waiting for data
	IN A,(UART)		  ; Place ready character into A
	RET



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

CRLF:           .asciiz     "\r\n"

TestLoadMsg:    .asciiz     "\r\n\r\nStart Test\r\n\r\n"

InvalidCommandMSG:  .asciiz "\r\nInvalid Command -- "

HelpMSG:        .asciiz "\r\nValid Commands. Use all CAPS.\r\nHELP -- Display this message\r\nREAD -- Read value\r\nWRITE -- Write Value\r\nBEEP -- Beep...\r\n"


Commands:
    defw    (HELP)      ;0
    defw    (READ)      ;2
    defw    (WRITE)     ;4
    defw    (BEEP)      ;6
    defw    $0000


HELP:   defb    4
HELPTEXT:    .ascii  "HELP"
READ:   defb    4
READTEST:    .ascii  "READ"
WRITE:  defb    5
WRITETEST:   .ascii  "WRITE"
BEEP:   defb    4
BEEPTEST:    .ascii  "BEEP"



    .org $4ffe

    .word $0000