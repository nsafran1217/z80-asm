

    
DIVISOR = $0C
UART = $00
UARTLSR = $05   
LCDR0 = $10
LCDR1 = $11
RAMSTART = $5000 
DATALEN = $1000

    .org $4000

;; $10 is RS = 0
;; $11 is RS = 1
    
setupSerial:
        LD SP,$ff00
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



SetupLCD:
    CALL lcdwait
    LD C,LCDR0
    LD A,00000001b          ;Clear
    OUT (C),A

    CALL lcdwait
    LD A,00000010b          ;Return home
    OUT (C),A
    

    CALL lcdwait
    LD A,00111000b          ;Set 8-bit mode,2 line display, 5x8 font
    
    OUT (C),A
    CALL lcdwait
    LD A,00001111b          ;Display on;curson on;blink on
    OUT (C),A
    CALL lcdwait
    LD A,00000110b          ;entrymode set;increment and shift cursor,dont shifft display
    OUT (C),A
    JP Main

Main:				
	CALL Input		

	CALL OutputLCDChar	
    ;LD A,$00
    ;CALL OutputChar
    ;CALL OutputAddress	

	JP Main



lcdwait:                    ;Check busy flag and wait until its ready
    PUSH AF
    PUSH BC
    LD C,LCDR0      
lcdwaitloop:
    IN A,(C)
    AND 10000000b           ;Get only busy flag
    JP NZ,lcdwaitloop       ;If flag not set, continue
    POP BC
    POP AF
    RET

OutputLCDChar:
    PUSH BC
    LD C,LCDR1               ;RS 1
    CALL lcdwait
    OUT (C),A               ;Send out character
    PUSH AF
    LD C,LCDR0              ;Now we set the next address  
    CALL lcdwait                   
    IN A,(C)                ;Get address register
    AND 01111111b           ;Ignore busy flag
    CP $14
    JP Z,Line2              ;we need to set to 40
    CP $40
    JP Z,Line4              ;we need to set to 54
    CP $54
    JP Z,Line3              ;We need to set to 14
    POP AF                  ;If we dont need to change address just pop
    POP BC
    RET                     ;and return
Line4:
    LD A,$54
    JP SetLCDAddr
Line2:
    LD A,$40
    JP SetLCDAddr
Line3:
    LD A,$14
    JP SetLCDAddr
SetLCDAddr:
    CALL lcdwait
    LD C,LCDR0
    OR 10000000b            ;Set the instruction we execute
    OUT (C),A               ;And set the address
    POP AF 
    POP BC
    RET

OutputAddress:
    PUSH AF
    PUSH BC
    LD C,LCDR0
    IN A,(C)
    AND 01111111b
    ;CALL TOHEX
    CALL OutputChar
    POP BC
    POP AF
    RET


;;Serial junk
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