    
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

        LD IY,initMessage       ;Load message address into index register IY
        CALL PrintStr           ;Print the message
        
        JP StartReadingData                ;Go to main loop
        


PrintStr: ;Print a string indexed in IY
        LD B,(IY)               ;LD into B value at address in IY
	    CALL Output             ;Output B
        INC IY                  ;INC IY, which is incrementing the address of the message
        LD A,(IY)               ;LD into A the next char to be printed
        CP $00                  ;Check if that char is 0. CP subtracts value from A but doesnt chnage A, only updates flags
        JP NZ,PrintStr          ;If its not 0, go back to Alert and continue printing
        RET
        


initMessage: .asciiz "\r\nStart Sending Data\n\r:"   ;needs the -esc option to treat these as cr and lf
dataLoadedMessage: .asciiz "\r\nData:\r\n"





StartReadingData:
    LD HL,RAMSTART              ;Load starting ram address into HL
    LD DE,DATALEN               ;Load length of data into DE
Main:				            ; Main read/write loop
	    CALL Input		        ; Read a byte from serial terminal
        ;CALL Output		        ; Echo it straight back out
        CALL StoreInRam
        DEC DE                  ;decrement bytes left to read
        LD A,D                  ;ld highbyte of DE into A
        CP $00                  ;check if zero
	    JP NZ, Main             ;if not keep looping
        LD A,E                  ;ld low byte of DE into A
        CP $00                  ;check if zero
        JP NZ, Main             ;if not keep looping
        LD HL,RAMSTART          ;if it is, set HL back to beginning of ram
        JP (HL)                 ;And start exectuon there



StoreInRam:                     ;Store entered character in RAM starting at $4000, we will increment everytime

        
        LD (HL),B  
        INC HL
        RET



;; Take a character in register B and output to the UART, toggling the GPIO LED
Output:
        IN A,($04)              ; Toggle OUT1 GPIO LED
        XOR %00000100
        OUT ($04), A
        LD C,UART               ; Write output UART port to reg C for use later
        OUT (C),B		; Send character to UART
LoopOut:			; Ensure the byte was transmitted
        IN A,(UARTLSR)              ; Read LSR
        BIT 6,A                 ; Check bit 6 (THR empty, line idle)
        JP Z,LoopOut
        RET

;; Read a character from the UART and place in register B
Input:
        LD C,UART               ; Write output UART port to reg C for use later
LoopIn:
	IN A,(UARTLSR)		; Read LSR
	BIT 0,A			; Check bit 0 (RHR byte ready)
	JP Z,LoopIn

	IN B,(C)		; Place ready character into B
	RET