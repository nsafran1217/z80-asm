    
DIVISOR = $0C
UART = $00
UARTLSR = $05   
RAMSTART = $5000 
DATALEN = $1000
    
    
    .org $4000                  ;Our rom starts at $0000 to $3FFF
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

        LD IY,splashScreen
        CALL PrintStr
   
        JP MainMenu             ;Go to main menu
        


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
        RET                     ;RETURN TO CALLER. VERY IMPORTANT
        

NewLine:
        LD IY,CRLF
        CALL PrintStr
        RET

MainMenu:
    
        LD IY,initMessage       ;Load message addrinto IY
        CALL PrintStr           ;Print message
        CALL Input               ;Wait for user Input
        CALL OutputChar         ;Echo char
        CP 'e'                  ;Is char e?
        JP Z, StartExecute4k    ;Yes, then StartExectuion
        CP 'v'                  ;Is char v?
        JP Z, ViewHexData
        CP 'l'
        JP Z, StartReadingData
        CP 'w'
        JP Z,WriteHexData
        CP 's'
        JP Z,StartExecuteAddr   ;specify address to execute from
        CP 'D'
        JP Z,DisableRom         ;go to disable rom subroutine
        JP MainMenu             ;If none match, reprint the message
WriteHexData:
        JP MainMenu             ;Not implemented
        CALL AskForAddress      ;Get address from user


ViewHexData:
        CALL AskForAddress      ;Get address from user
        CALL OutputHexData      ;output $80 data starting at HL
        JP MainMenu

StartReadingData:
        LD IY,loadMessage       ;Load message address into index register IY
        CALL PrintStr           ;Print the message
        LD HL,RAMSTART          ;Load starting ram address into HL
        LD DE,DATALEN           ;Load length of data into DE
ReadLoop:			; Main read/write loop
	CALL Input		; Read a byte from serial terminal
        ;CALL Output
        CALL StoreInRam
        DEC DE                  ;decrement bytes left to read
        LD A,D                  ;ld highbyte of DE into A
        CP $00                  ;check if zero
	JP NZ, ReadLoop         ;if not keep looping
        LD A,E                  ;ld low byte of DE into A
        CP $00                  ;check if zero
        JP NZ, ReadLoop         ;if not keep looping
        ;if it is, Go back to main menu and print Message
        LD IY,dataLoadedMessage
        CALL PrintStr
        JP MainMenu

StartExecute4k:
        CALL NewLine
        LD HL,RAMSTART          ;Set ram address back to start
        JP (HL)                 ;And start exectuon there

StartExecuteAddr:
        CALL NewLine
        CALL AskForAddress      ;Get addr from user
        CALL NewLine
        JP (HL)                 ;And start exectuon there

DisableRom:
        PUSH BC
        LD C,$70                ;Load disable rom address
        LD B,$01                ;Load disable rom bit
        OUT (C),B               ;send bit
        POP BC
        JP MainMenu       

;;Asks user to input hex address, stores in HL Destorys all registers
AskForAddress:
        LD IY,WhatAddrMessage   
        CALL PrintStr 
        LD D,$04                ;Get 4 charcters
        LD HL,$0000
AskForAddressLoop:   
        CALL Input
        CALL OutputChar
        ;;LD A,B                ;;we now use A for input and output
        CALL ATOHEX             ;Convert hex ascii to real number
        PUSH AF                 ;push value to stack
        DEC D                   ;Dec char counter
        LD A,D                  ;Move D to A
        CP $00                  ;Is 0?
        JP NZ,AskForAddressLoop ;Keep going if we need more CHARS

        POP AF                  ;get low nibble
        LD B,A                  ;put into B
        POP AF                  ;get high nibble
        RLC A                   ;shift nibble left 4 times
        RLC A
        RLC A
        RLC A
        OR B                    ;or with low nibble

        LD L,A                  ;load low byte 
 
        POP AF
        LD B,A
        POP AF
        RLC A
        RLC A
        RLC A
        RLC A
        OR B
        LD H,A                  ;load high byte 
        RET


ResetD:
    LD D,$00
    RET
;;Output $80 address in a table starting at address in HL. Destorys all registers
OutputHexData:
        CALL NewLine
        ;;LD HL,RAMSTART          ;Set ram address back to start
        LD E,$80                ;Load length of data  to display into D
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte
        LD A,'-'
        CALL OutputChar
        PUSH HL                 ;Push HL to retrieve later. This contains the real address we need

        ADC HL,DE               ;16 bit add
              
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte

        POP HL                  ; restore HL to the real address
        CALL NewLine
        CALL ResetD
OutputHexLoop:
        LD A,(HL)
        CALL hexout             ;print A as hex char
        LD A,' '
        CALL OutputChar
        INC HL                  ;Inc ram address
        DEC E                   ;Dec address left to display
        INC D                   ;Inc number display per line
        LD A,D                  ;Check is we've printed 16 bytes
        CP $10                  
        CALL Z, NewLine         ;If we did do a new line and reset the counter
        CALL Z, ResetD
        LD A,E                  ;ld count of bytes left to display
        CP $00                  ;check if zero
        JP NZ, OutputHexLoop    ;if not keep displaying


        LD IY,KeepPrintMessage  ;Ask if user wants to view more hex
        CALL PrintStr           ;Print
        CALL Input
        LD E,$80                ;Reset D incase we want to print more
        ;LD A,B                  ;;we now use A for input and output
        CP 'c'                  ;is input C?
        JP Z,OutputHexData      ;Yes, print more hex,
        RET                     ;else, go back
               

StoreInRam:                     ;Store A into RAM at HL. This increments HL
        LD (HL),A               ;Load A into address HL points to
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



;; Take a character in register A and output to the UART, toggling the GPIO LED
OutputChar:
        PUSH BC                 ; PUSH BC to stack
        LD B,A                  ;Move char into B
        PUSH AF                 ;store A safely
        IN A,($04)              ; Toggle OUT1 GPIO LED
        XOR %00000100
        OUT ($04), A
        LD C,UART               ; Write output UART port to reg C for use later
        OUT (C),B		; Send character to UART

LoopOut:			; Ensure the byte was transmitted
        IN A,(UARTLSR)          ; Read LSR
        BIT 6,A                 ; Check bit 6 (THR empty, line idle)
        JP Z,LoopOut
        POP AF                  ;bring back our registers
        POP BC
        RET

;; Read a character from the UART and place in register A
Input:
        PUSH BC
        LD C,UART               ; Write output UART port to reg C for use later
LoopIn:
	IN A,(UARTLSR)		        ; Read LSR
	BIT 0,A			            ; Check bit 0 (RHR byte ready)
	JP Z,LoopIn                 ; If zero, keep waiting for data
	IN A,(C)		            ; Place ready character into A
        POP BC
	RET

splashScreen: .asciiz "\r\n\r\nWelcome to Z80 ROM MONITOR\r\n (c)Nathan Safran 2021\r\n\r\n\r\n"
initMessage: .asciiz "\r\nEnter l to load data into RAM\r\nEnter v to view a HEX address\r\nEnter w to write value to address\r\nPress e to jump execution to $4000\r\nEnter s to jump execution to specified address\r\nEnter D to disable ROM\r\n:"
loadMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000\r\nYou may have to send 1 more byte after loading\r\nReady to load:\r\n"   ;needs the -esc option to treat these as cr and lf
;;initMessage: .asciiz "test"
dataLoadedMessage: .asciiz "\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\nData has been loaded into RAM\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\n"
CRLF: .asciiz "\r\n"
KeepPrintMessage: .asciiz"\r\nPress c to continue printing\r\nPress any key to return to menu\r\n"
WhatAddrMessage: .asciiz "\r\nEnter address in HEX. Capital letters only\r\n"

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


    .org $4ffe

    .word $0000