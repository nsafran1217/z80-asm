    
DIVISOR = $0C
UART = $00
UARTLSR = $05   
RAMSTART = $4000 
DATALEN = $1000 ;4k bytes

IDESTATUS = $47
IDESECTORCOUNT = $42
IDELBABITS0TO7 = $43
IDELBABITS8TO15 = $44
IDELBABITS15TO23 = $45
IDEDRIVEHEADREG = $46
IDEDATAREG = $40
    
               ;;YOU NEED TO MANUALLY REMOVE THE ZERO PADDING AND FIX THE LD INSTRUCTIONS. CODE_END -  code_start NEEDS FIXED
;Code to start program and move to higher memory
;
        .org	$0100
        ld	hl,code_origin	;start of code to transfer
        ld	bc,code_end-code_start+1	;length of code to transfer
        ld	de,$B000	;target of transfer
        ldir			;Z80 transfer instruction
        jp	$B000
code_origin: 					;address of first byte of code before transfer
;	
       .org $B000
code_start:			
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
        RET
        
NewLine:
        LD IY,CRLF
        CALL PrintStr
        RET

MainMenu:

        LD IY,initMessage       ;Load message addrinto IY
        CALL PrintStr           ;Print message
        CALL Input               ;Wait for user Input
        CALL OutputChar         ;Echo char
        CP 'v'                  
        JP Z, ViewHexData
        CP 'L'
        JP Z,LoadDataToAddress
        CP 'w'
        JP Z,WriteHexData
        CP 's'
        JP Z,StartExecuteAddr   ;specify address to execute from
        CP 'R'
        JP Z,ReadDataFromHDD
        CP 'W'
        JP Z,WriteDataToHDD
        CP 'C'
        JP Z,$FA00
        JP MainMenu             ;If none match, reprint the message

ReadDataFromHDD:
        LD IY,ReadWriteDataToHDDMSG
        CALL PrintStr
        CALL AskForHex
        LD C,L
        CALL NewLine
        CALL AskForHex
        LD B,L
        CALL NewLine
        CALL AskForHex
        LD E,L
        CALL NewLine
        CALL AskForHex
        CALL NewLine
        CALL disk_read

        JP MainMenu
WriteDataToHDD
        LD IY,AreYouSureMsg
        CALL PrintStr
        CALL Input
        CP 'Y'
        JP NZ, MainMenu
        LD IY,ReadWriteDataToHDDMSG
        CALL PrintStr
        CALL AskForHex
        LD C,L
        CALL NewLine
        CALL AskForHex
        LD B,L
        CALL NewLine
        CALL AskForHex
        LD E,L
        CALL NewLine
        CALL AskForHex
        CALL NewLine
        CALL disk_write
        JP MainMenu
WriteHexData:
        NOP
        JP MainMenu             ;Not implemented
        CALL AskForHex      ;Get address from user


LoadDataToAddress:
        LD IY,WhatAddrMessage   
        CALL PrintStr 
        CALL AskForHex
        PUSH HL
        LD IY,WhatDataLenMessage   
        CALL PrintStr 
        CALL AskForHex
        LD D,H
        LD E,L
        POP HL
        LD IY,beginLoadMessage       ;Load message address into index register IY
        CALL PrintStr           ;Print the message
        JP ReadDataLoop


ReadDataLoop:			; Main read/write loop
	CALL Input		; Read a byte from serial terminal
        ;CALL Output
        CALL StoreInRam
        DEC DE                  ;decrement bytes left to read
        LD A,D                  ;ld highbyte of DE into A
        CP $00                  ;check if zero
	JP NZ, ReadDataLoop         ;if not keep looping
        LD A,E                  ;ld low byte of DE into A
        CP $00                  ;check if zero
        JP NZ, ReadDataLoop         ;if not keep looping
        ;if it is, Go back to main menu and print Message
        LD IY,dataLoadedMessage
        CALL PrintStr
        JP MainMenu


StartExecuteAddr:
        LD IY,WhatAddrMessage   
        CALL PrintStr 
        CALL AskForHex     ;Get addr from user
        CALL NewLine
        JP (HL)                 ;And start exectuon there

;;Gets 4 digit hex number from user, stores in HL Destorys all registers
AskForHex:
        LD HL,$0000
        LD D,$04
AskForHexLoop:   
        CALL Input
        CALL OutputChar
        ;;LD A,B                ;;we now use A for input and output
        CALL ATOHEX             ;Convert hex ascii to real number
        PUSH AF                 ;push value to stack
        DEC D                   ;Dec char counter
        LD A,D                  ;Move D to A
        CP $00                  ;Is 0?
        JP NZ,AskForHexLoop ;Keep going if we need more CHARS

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

ViewHexData:
        LD IY,WhatAddrMessage   
        CALL PrintStr 
        LD D,$04                ;Get 4 charcters
        CALL AskForHex      ;Get address from user
        CALL OutputHexData      ;output $80 data starting at HL
        JP MainMenu
ResetD:
    LD D,$00
    RET
;;Output $80 address in a table starting at address in HL. Destorys all registers
OutputHexData:
        CALL NewLine

        LD E,$7F                ;Load length of data to display into E -1 so the displayed address is correct
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

        LD E,$80                ;Load length of data to display into E
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
        CP ' '                  ;is input space?
        JP Z,OutputHexData      ;Yes, print more hex,
        RET                     ;else, go back to caller
               

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

	

;Subroutine to read one disk sector (256 bytes)
;Address to place data passed in HL
;LBA bits 0 to 7 passed in C, bits 8 to 15 passed in B
;LBA bits 16 to 23 passed in E
disk_read:
rd_status_loop_1:	
        in	a,(IDESTATUS)		;check status
        and	80h		        ;check BSY bit
        jp	nz,rd_status_loop_1	;loop until not busy
rd_status_loop_2:	
        in	a,(IDESTATUS)		;check	status
        and	40h		        ;check DRDY bit
        jp	z,rd_status_loop_2	;loop until ready
        ld	a,01h		        ;number of sectors = 1
        out	(IDESECTORCOUNT),a	;sector count register
        ld	a,c
        out	(IDELBABITS0TO7),a	;lba bits 0 - 7
        ld	a,b
        out	(IDELBABITS8TO15),a	;lba bits 8 - 15
        ld	a,e
        out	(IDELBABITS15TO23),a	;lba bits 16 - 23
        ld	a,11100000b	        ;LBA mode, select drive 0
        out	(IDEDRIVEHEADREG),a	;drive/head register
        ld	a,20h		        ;Read sector command
        out	(IDESTATUS),a
rd_wait_for_DRQ_set:	
        in	a,(IDESTATUS)		;read status
        and	08h		        ;DRQ bit
        jp	z,rd_wait_for_DRQ_set	;loop until bit set
rd_wait_for_BSY_clear:	
        in	a,(IDESTATUS)
        and	80h
        jp	nz,rd_wait_for_BSY_clear
        in	a,(IDESTATUS)		;clear INTRQ
read_loop:
        in      a,(IDEDATAREG)          ;get data
        ld	(hl),a
        inc	hl
        in	a,(IDESTATUS)		;check status
        and	08h		        ;DRQ bit
        jp	nz,read_loop	        ;loop until cleared
        ret

;
;Subroutine to write one disk sector (256 bytes)
;Address of data to write to disk passed in HL
;LBA bits 0 to 7 passed in C, bits 8 to 15 passed in B
;LBA bits 16 to 23 passed in E
disk_write:
wr_status_loop_1:	
        in	a,(IDESTATUS)		        ;check status
        and	80h		        ;check BSY bit
        jp	nz,wr_status_loop_1	;loop until not busy
wr_status_loop_2:	
        in	a,(IDESTATUS)		        ;check	status
        and	40h		        ;check DRDY bit
        jp	z,wr_status_loop_2	;loop until ready
        ld	a,01h		        ;number of sectors = 1
        out	(IDESECTORCOUNT),a	 ;sector count register
        ld	a,c
        out	(IDELBABITS0TO7),a      ;lba bits 0 - 7
        ld	a,b
        out	(IDELBABITS8TO15),a     ;lba bits 8 - 15
        ld	a,e
        out	(IDELBABITS15TO23),a    ;lba bits 16 - 23
        ld	a,11100000b	        ;LBA mode, select drive 0
        out	(IDEDRIVEHEADREG),a     ;drive/head register
        ld	a,30h		        ;Write sector command
        out	(IDESTATUS),a
wr_wait_for_DRQ_set:	
        in	a,(IDESTATUS)           ;read status
        and	08h		        ;DRQ bit
        jp	z,wr_wait_for_DRQ_set	;loop until bit set			
write_loop:		
        ld	a,(hl)
        out	(IDEDATAREG),a          ;write data
        inc	hl
        in	a,(IDESTATUS)           ;read status
        and	08h		        ;check DRQ bit
        jp	nz,write_loop	        ;write until bit cleared
wr_wait_for_BSY_clear:	
        in	a,(IDESTATUS)
        and	80h
        jp	nz,wr_wait_for_BSY_clear
        in	a,(IDESTATUS)           ;clear INTRQ
        ret



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

splashScreen: .asciiz "\r\n\r\nWelcome to Z80 ROM MONITOR\r\n (c)Nathan Safran 2021\r\n\r\n\r\n"
initMessage: .asciiz "\r\nEnter L to load data to specified address\r\nEnter v to view a HEX address\r\nEnter w to write value to address\r\nEnter s to jump execution to specified address\r\nEnter R to read data from HDD\r\nEnter W to write data to HDD\r\nEnter C to return to CP/M\r\n:"
loadMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000S\r\nReady to load:\r\n"   ;needs the -esc option to treat these as cr and lf
beginLoadMessage: .asciiz "\r\nBegin sending data:\r\n"
;;initMessage: .asciiz "test"
dataLoadedMessage: .asciiz "\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\nData has been loaded into RAM\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\n"
CRLF: .asciiz "\r\n"
KeepPrintMessage: .asciiz"\r\nPress SPACE BAR to continue printing\r\nPress any key to return to menu\r\n"
WhatAddrMessage: .asciiz "\r\nEnter address in HEX. Capital letters only\r\n"
WhatDataLenMessage: .asciiz "\r\nEnter data length in HEX. Capital letters only\r\n"
ReadWriteDataToHDDMSG: .asciiz "\r\nEnter the following data in HEX caps only (4 Digits each):\r\nTrack\r\nSector\r\nDisk\r\nAddress to read/write data\r\n"
AreYouSureMsg: .asciiz "\r\nAre you sure? This can destoy data.\r\nEnter Y to continue, any key to go back to menu\r\n:"
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


code_end:
        end