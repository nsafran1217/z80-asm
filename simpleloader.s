    
DIVISOR = $0C
UART = $00
UARTLSR = $05   
RAMSTART = $4000 
DATALEN = $1000
    
    
    .org $0000                  ;Our rom starts at $0000 to $3FFF
                                ;RAM from $4000 to $ffff


Setup:
        ; Bring up OUT2 GPIO pin first, so we know things are starting like they're supposed to
        IN A,($04)
        OR %00001000            ;Bit 3 is GPIO2
        OUT ($04), A

        ; Set Divisor Latch Enable
        LD A,%10000000          ; Set Div Latch Enable to 1
        OUT ($03),A             ; Write LCR
        ; Set divisor to 12 (1.8432 MHz / 12 / 16 = 9600bps)
        LD A,DIVISOR
        OUT ($00),A             ; DLL 0x0C (#12)
        LD A,$00
        OUT ($01),A             ; DLM 0x00

        LD A,%00000011          ; Set DLE to 0, Break to 0, No parity, 1 stop bit, 8 bytes
        OUT ($03),A             ; Write now configured LCR

	    LD SP,$ff00		        ; Initialise the stack pointer to $ff00 (it will grow DOWN in RAM)

        
        JP StartReadingData     ;Start waiting for data to read
        


PrintStr: ;Print a string indexed in IY
        LD B,(IY)               ;LD into B value at address in IY
	    CALL OutputChar         ;Output B
        INC IY                  ;INC IY, which is incrementing the address of the message
        LD A,(IY)               ;LD into A the next char to be printed
        CP $00                  ;Check if that char is 0. CP subtracts value from A but doesnt chnage A, only updates flags
        JP NZ,PrintStr          ;If its not 0, go back to Alert and continue printing
        RET                     ;RETURN TO CALLER. VERY IMPORTANT
        

initMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000\r\nYou may have to send 1 more byte after loading\r\nReady to load:\r\n"   ;needs the -esc option to treat these as cr and lf
;;initMessage: .asciiz "test"
dataLoadedMessage: .asciiz "\r\nEnter e to start execution\r\nEnter v to view data in HEX\r\nEnter l to load new data\r\n:"
CRLF: .asciiz "\r\n"
KeepPrintMessage: .asciiz"\r\nPress c to continue printing\r\nPress any key to return to menu\r\n"

NewLine:
    LD IY,CRLF
    CALL PrintStr
    RET


StartReadingData:
        LD IY,initMessage       ;Load message address into index register IY
        CALL PrintStr           ;Print the message
        LD HL,RAMSTART          ;Load starting ram address into HL
        LD DE,DATALEN           ;Load length of data into DE
ReadLoop:				        ; Main read/write loop
	    CALL Input		        ; Read a byte from serial terminal
        ;CALL Output
        CALL StoreInRam
        DEC DE                  ;decrement bytes left to read
        LD A,D                  ;ld highbyte of DE into A
        CP $00                  ;check if zero
	    JP NZ, ReadLoop         ;if not keep looping
        LD A,E                  ;ld low byte of DE into A
        CP $00                  ;check if zero
        JP NZ, ReadLoop         ;if not keep looping
        ;if it is, Keep going to ReadyToExecute

ReadyToExecute:                 ;Prompt user for input, either print , excecute, or reload data
        
        LD IY,dataLoadedMessage ;Load message addrinto IY
        CALL PrintStr           ;Print message
        CALL Input              ;Wait for user Input
        CALL OutputChar         ;Echo char
        LD A,B                  ;Load char into A
        CP 'e'                  ;Is char e?
        JP Z, StartExecution     ;Yes, then StartExectuion
        CP 'v'                  ;Is char v?
        JP Z, OutputHexData
        CP 'l'
        JP Z, StartReadingData
        JP ReadyToExecute       ;If none match, reprint the message

StartExecution:
        CALL NewLine
        LD HL,RAMSTART          ;Set ram address back to start
        JP (HL)                 ;And start exectuon there
ResetE:
    LD E,$00
    RET
OutputHexData:
        CALL NewLine
        LD HL,RAMSTART          ;Set ran address back to start
        LD D,$80                ;Load length of data  to display into D
        CALL ResetE
OutputHexLoop:
        LD A,(HL)
        CALL hexout             ;print A as hex char
        LD B,' '
        CALL OutputChar
        INC HL
        DEC D
        INC E
        LD A,E  
        CP $10
        CALL Z, NewLine
        CALL Z, ResetE
        LD A,D                  ;ld highbyte of DE into A
        CP $00                  ;check if zero
        JP NZ, OutputHexLoop    ;if not keep looping


        LD IY,KeepPrintMessage  ;Ask if user wants to view more hex
        CALL PrintStr           ;Print
        CALL Input
        LD D,$80                ;Reset D incase we want to print more
        LD A,B
        CP 'c'                  ;is input C?
        JP Z,OutputHexLoop      ;Yes, print more hex,
        JP ReadyToExecute       ;else, go back to menu
               

StoreInRam:                     ;Store entered character in RAM starting at $4000, we will increment everytime 
        LD (HL),B               ;Load B into address HL points to
        INC HL                  ; INC HL to next address
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
		PUSH BC
        LD B,A
        CALL OutputChar
        POP BC
		
		; Lower nybble
		LD A, B
		AND 0FH
		CALL TOHEX
        PUSH BC
        LD B,A
		CALL OutputChar
        POP BC
		
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



;; Take a character in register B and output to the UART, toggling the GPIO LED
OutputChar:
        IN A,($04)              ; Toggle OUT1 GPIO LED
        XOR %00000100
        OUT ($04), A
        LD C,UART               ; Write output UART port to reg C for use later
        OUT (C),B		        ; Send character to UART
LoopOut:			            ; Ensure the byte was transmitted
        IN A,(UARTLSR)          ; Read LSR
        BIT 6,A                 ; Check bit 6 (THR empty, line idle)
        JP Z,LoopOut
        RET

;; Read a character from the UART and place in register B
Input:
        LD C,UART               ; Write output UART port to reg C for use later
LoopIn:
	IN A,(UARTLSR)		        ; Read LSR
	BIT 0,A			            ; Check bit 0 (RHR byte ready)
	JP Z,LoopIn                 ; If zero, keep waiting for data
	IN B,(C)		            ; Place ready character into B
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


