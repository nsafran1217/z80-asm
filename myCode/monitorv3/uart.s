;This file contains routines for input and output for the UART
DIVISOR = $0C               ;9600 baud
UART = $00                  ;UART Address
UARTLSR = $05  
;Initialize UART
SetupUART:
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
        RET

;Send byte in A to serial
OutputChar:
        OUT (UART),A		    ; Send character to UART
        PUSH AF
LoopOut:			            ; Ensure the byte was transmitted
        IN A,(UARTLSR)          ; Read LSR
        BIT 6,A                 ; Check bit 6 (THR empty, line idle)
        JP Z,LoopOut
        POP AF                  ;bring back our registers

        RET

;; Read a character from the UART and place in register A
InputChar:
	IN A,(UARTLSR)		        ; Read LSR
	BIT 0,A			            ; Check bit 0 (RHR byte ready)
	JP Z,InputChar                ; If zero, keep waiting for data
	IN A,(UART)		            ; Place ready character into A
	RET

;Read a string terminated with CR into buffer address (HL)
;Replace CR with NUL
;Returns (HL) address of NUL term string
ReadLine:
        PUSH HL
ReadLineLoop:
        CALL InputChar
        CP "\r"                 ;If its a \r, we're done
        JP Z, EndOfLine
        CP $08                  ;Backspace
        JP Z, BackSpace
        CALL OutputChar
        LD (HL), A
        INC HL
        JP ReadLineLoop
EndOfLine:
        LD (HL), 0              ;We put a NUL at the end of the string       
        POP HL
        RET

BackSpace:
        DEC HL
        LD A, (HL)
        CP $00                  ;If last char entered is not NUL
        JP NZ, DelChar          ;Jump to DelChar
        INC HL                  ;Put HL back to the proper location
        JP ReadLineLoop         ;In this case,we can go back to readlineloop, since theres nothing to do
 
DelChar:
        LD A, $08               ;Backspace
        CALL OutputChar
        LD A, $1B               ;ANSI Escape
        CALL OutputChar
        LD A, '['
        CALL OutputChar
        LD A, 'K'               ;Erase in Line. From cursor to end
        CALL OutputChar
        JP ReadLineLoop         ;Can just jump back to readlineloop. HL is wheree we want it.

