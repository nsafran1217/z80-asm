

    
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
    
setup:
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


    CALL lcdwait
    LD A,00000001b          ;Display clear
    LD C,LCDR0
    OUT (C),A
    CALL lcdwait
    LD A,00110000b         ;Function set; 8 bit mode, basic instructions
    LD C,LCDR0
    OUT (C),A
        CALL lcdwait
    LD A,00110000b         ;Function set; 8 bit mode, basic instructions
    LD C,LCDR0
    OUT (C),A
        CALL lcdwait
    LD A,00001111b          ;Display control; Set Display on, cursor on, blink on
    LD C,LCDR0
    OUT (C),A
        CALL lcdwait
    LD A,00000110b          ;Entry Mode set;increment and shift cursor;dont shifft display
    LD C,LCDR0
    OUT (C),A

        CALL lcdwait
    LD A,00010100b         ;Cursor display control;cursor moves right by 1. LH
    LD C,LCDR0
    OUT (C),A
        CALL lcdwait
    LD A,00000001b          ;Display clear
    LD C,LCDR0
    OUT (C),A

    ;CALL lcdwait

    LD A,'H'
    CALL OutputLCDChar
    LD A,'e'
    CALL OutputLCDChar
    LD A,'l'
    CALL OutputLCDChar
    LD A,'p'
    CALL OutputLCDChar

    JP Main


lcdwait:
    PUSH AF
    ;PUSH BC
    LD C,LCDR0
    
lcdwaitloop:
    IN A,(C)
    AND 10000000b
    JP NZ,lcdwaitloop
    ;POP BC
    POP AF
    RET

OutputLCDChar:
    CALL lcdwait
    LD C,LCDR1               ;RS 1
    OUT (C),A
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

Main:				; Main read/write loop
	CALL Input		; Read a byte from serial terminal

	CALL OutputLCDChar		; Echo it straight back out

	JP Main
















    JP $0000
    .org $4ffe

    .word $0000