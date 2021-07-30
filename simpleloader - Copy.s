    
DIVISOR = $0C
UART = $80
UARTLSR = $85   
RAMSTART = $4000 
DATALEN = $1000
    
    
    .org $0000                  ;Our rom starts at $0000 to $3FFF
                                ;RAM from $4000 to $ffff


Setup:
        ; Bring up OUT2 GPIO pin first, so we know things are starting like they're supposed to
        IN A,($84)
        OR %00001000            ;Bit 3 is GPIO2
        OUT ($84), A

        ; Set Divisor Latch Enable
        LD A,%10000000          ; Set Div Latch Enable to 1
        OUT ($83),A             ; Write LCR
        ; Set divisor to 12 (1.8432 MHz / 12 / 16 = 9600bps)
        LD A,DIVISOR
        OUT ($80),A             ; DLL 0x0C (#12)
        LD A,$00
        OUT ($81),A             ; DLM 0x00

        LD A,%00000011          ; Set DLE to 0, Break to 0, No parity, 1 stop bit, 8 bytes
        OUT ($83),A             ; Write now configured LCR

	    LD SP,$ff00		        ; Initialise the stack pointer to $ff00 (it will grow DOWN in RAM)

        
        JP StartReadingData     ;Start waiting for data to read
        


PrintStr: ;Print a string indexed in IY
        LD B,(IY)               ;LD into B value at address in IY
	    CALL OutputChar         ;Output B
        INC IY                  ;INC IY, which is incrementing the address of the message
        LD A,(IY)               ;LD into A the next char to be printed
        CP $00                  ;Check if that char is 0. CP subtracts value from A but doesnt chnage A, only updates flags
        JP NZ,PrintStr          ;If its not 0, go back to Alert and continue printing
        

initMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000\r\nYou may have to send 1 more byte after loading\r\nReady to load:\r\n"   ;needs the -esc option to treat these as cr and lf
dataLoadedMessage: .asciiz "\r\nEnter e to start execution\r\nEnter v to view data in HEX\r\nEnter l to load new data\r\n:"


StartReadingData:
        LD IY,initMessage       ;Load message address into index register IY
        CALL PrintStr           ;Print the message
        LD HL,RAMSTART          ;Load starting ram address into HL
        LD DE,DATALEN           ;Load length of data into DE
ReadLoop:				        ; Main read/write loop
	    CALL Input		        ; Read a byte from serial terminal

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
        LD HL,RAMSTART          ;Set ram address back to start
        JP (HL)                 ;And start exectuon there

OutputHexData:
        LD HL,RAMSTART          ;Set ran address back to start
        LD DE,DATALEN           ;Load length of data into DE
        LD A,(HL)
        CP $0A
        SBC a,$69
        DAA
        LD B,A
        CALL OutputChar
        DEC DE
        LD A,D
        CP $00
        JP NZ, OutputHexData
        LD A,E                  ;ld low byte of DE into A
        CP $00                  ;check if zero
        JP NZ, OutputHexData         ;if not keep looping



StoreInRam:                     ;Store entered character in RAM starting at $4000, we will increment everytime 
        LD (HL),B               ;Load B into address HL points to
        INC HL                  ; INC HL to next address
        RET

;; Take a character in register B and output to the UART, toggling the GPIO LED
OutputChar:
        IN A,($84)              ; Toggle OUT1 GPIO LED
        XOR %00000100
        OUT ($84), A
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