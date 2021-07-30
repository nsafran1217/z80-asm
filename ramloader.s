    
DIVISOR = $0C
UART = $00
UARTLSR = $05   
RAMSTART = $4000 
DATALENADDR = $A000
TRUEDATALEN = $9F00
    
    
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
        
        JP GetDataLength                ;Go to main loop
        


PrintStr: ;Print a string indexed in IY
        LD B,(IY)               ;LD into B value at address in IY
	    CALL Output             ;Output B
        INC IY                  ;INC IY, which is incrementing the address of the message
        LD A,(IY)               ;LD into A the next char to be printed
        CP $00                  ;Check if that char is 0. CP subtracts value from A but doesnt chnage A, only updates flags
        JP NZ,PrintStr          ;If its not 0, go back to Alert and continue printing
        


initMessage: .asciiz "\r\nEnter Data Length in Bytes\n\r:"   ;needs the -esc option to treat these as cr and lf
dataLoadedMessage: .asciiz "\r\nData:\r\n"


GetDataLength:
        LD HL,DATALENADDR       ;Load starting ram address into HL
GetDataLenLoop:
    	CALL Input		        ; Read a byte from serial terminal
        LD A,B                  ;Load inputted char to A
        CP $0D                  ;Check if A contains a CR
        CALL Z,CREntered          ;JP if A is CR
        LD A,B                  ;Load inputted char to A
        CP $0D                  ;Check if A contains a CR
        CALL NZ, StoreInRam
        LD A,B                  ;Load inputted char to A
        CP $0D                  ;Check if A contains a CR
	    JP NZ, GetDataLength
        JP ConvertAsciiToBytes

StoreInRam:                     ;Store entered character in RAM starting at $4000+1, we will increment everytime
        INC HL
        LD (HL),B  
        RET

CREntered:                      ;Handle a CR being entered
        INC HL                  ;Inc to new spot
        LD (HL),$00             ;Put a 0 there
        LD HL,DATALENADDR       ; Go back to start 
        LD B,$0D                ;Load CR to Output
        CALL Output
        LD B, $0A               ;Load LF to Output
        CALL Output
        LD B, '='               
        CALL Output      
OutputRamLoop:
        INC HL                  ;Move to RAMSTART + 1
        LD B,(HL)               ;LD B with value in RAM
        CALL Output             ;Output ram
        LD A,B                  ;move data into A
        CP $00                  ;cehck if data is zero
        JP NZ, OutputRamLoop    ;if its not zero, keep outputing
                                ; when its zero we
        LD B,$0A                ;Output newline char
        CALL Output
        LD B, $0D               ;Load LF to Output
        CALL Output 

        RET                     ;RET back to caller
        
ConvertAsciiToBytes:
        LD IY,TRUEDATALEN
        LD HL,DATALENADDR       ;Putt address of bytes in HL
        INC HL
        LD A,(HL)
        CP $00                  ; check if value is $00 AKA NULL
        JP Z, DoneConvertAscii  ;JP out of conversion loop  
        SUB $38                 ;subtract 48 to get the number. This is the ones place
        LD (IY),A      ;store value to ram
        INC HL
        LD A,(HL)
        CP $00
        JP Z, DoneConvertAscii
        SUB $38
        ADD A,A
        ADD A,A                 ;multyply 10s by 10
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,(IY)
        LD (IY),A           ;ones and 10s place added.


        



        
DoneConvertAscii:






StartReadingData:
    LD HL,RAMSTART              ;Load starting ram address into HL
Main:				            ; Main read/write loop
	    CALL Input		        ; Read a byte from serial terminal
        LD A,B                  ;Load inputted char to A
        CP $0D                  ;Check if A contains a CR
        JP Z,CREntered          ;JP if A is CR
        CALL StoreInRam
	    JP Main



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