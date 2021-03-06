RAMSTART = $4000 
DATALEN = $1000 ;4k bytes


    .org $0000
    .include copyfromromtoram.s

    JP Start
    .org $0030
Disk_read_jump:                     ;this is a patch until I change and write a new version of diskcpmloader.s to the HDD 
        CALL disk_read            ;Known address of $0030 for the disk read subroutine
        ret
Start:
    LD SP,$ffff
    CALL SetupUART
    LD IY,splashScreen
    CALL PrintStr
    JP MainMenu


    .include uart.s
    .include String.s
    .include hexout.s
    .include hexdump.s
    ;.include printregs.s
    .include ide.s

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCMD:

    LD IY,WhatAddrMessage   
    CALL PrintStr 
    CALL AskForHex              ;Get address from user
    CALL NewLine
    LD A, (HL)
    CALL hexout
    CALL NewLine
    JP MainMenu

WriteCMD:
  
    LD IY,WhatAddrMessage   
    CALL PrintStr 
    CALL AskForHex              ;Get address from user
    PUSH HL
    LD IY,WhatValMessage   
    CALL PrintStr

    CALL AskForHex              ;Value to write is in L
    LD A,L
    POP HL
    LD (HL),A
    JP MainMenu                 

LoadCMD4k:
    LD IY,loadMessage           ;Load message address into index register IY
    CALL PrintStr               ;Print the message
    LD HL, RAMSTART             ;Load starting ram address into HL
    LD DE, DATALEN              ;Load length of data into DE
    CALL ReadDataLoop
    JP MainMenu

LoadCMD:
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
    LD IY,beginLoadMessage  ;Load message address into index register IY
    CALL PrintStr           ;Print the message
    CALL ReadDataLoop
    JP MainMenu

StartExecute4k:
    CALL NewLine
    LD HL,RAMSTART          ;Set ram address back to start
    JP (HL)                 ;And start exectuon there

StartExecuteAddr:
    LD IY,WhatAddrMessage   
    CALL PrintStr 
    CALL AskForHex          ;Get addr from user
    CALL NewLine
    JP (HL)                 ;And start exectuon there
ViewHexData:
        LD IY,WhatAddrMessage   
        CALL PrintStr 
        LD D,$04                ;Get 4 charcters
        CALL AskForHex      ;Get address from user
        CALL OutputHexData      ;output $80 data starting at HL
        JP MainMenu

CPMCMD:
        ld	hl,4000h        ;Get CP/m Loader off disk and store in begining of RAM
        ld	bc,0000h
        ld	e,00h
        call 	disk_read
        jp	4000h           ;CP/M Loader that was just pulled off the disk

BeepCMD:
    LD A, $07                   ;Bell character
    CALL OutputChar
    JP MainMenu

SoftRestart:
    JP Start

    
ReadDataFromHDDCMD:
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
WriteDataToHDDCMD:
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



MainMenu:

    LD IY,MainMenuMSG       ;Load message addrinto IY
    CALL PrintStr           ;Print message
    CALL Input               ;Wait for user Input
    CALL OutputChar         ;Echo char
    CP 'e'                  ;Is char e?
    JP Z, StartExecute4k    ;Yes, then StartExectuion
    CP 'v'                  
    JP Z, ViewHexData
    CP 'l'
    JP Z, LoadCMD4k
    CP 'L'
    JP Z,LoadCMD
    CP 'w'
    JP Z,WriteCMD
    CP 'r'
    JP Z,ReadCMD
    CP 's'
    JP Z,StartExecuteAddr   ;specify address to execute from
    CP 'C'
    JP Z,CPMCMD
    CP 'F'
    JP Z,FDDMenu
    CP 'H'
    JP Z,HDDMenu
    CP 'R'
    JP Z,SoftRestart

    JP MainMenu            

HDDMenu:
    LD IY,HDDMenuMSG       ;Load message addrinto IY
    CALL PrintStr           ;Print message
    CALL Input               ;Wait for user Input
    CALL OutputChar         ;Echo char
    CP 'R'
    JP Z,ReadDataFromHDDCMD
    CP 'W'
    JP Z,WriteDataToHDDCMD
    JP MainMenu     

FDDMenu:
    LD IY,FDDMenuMSG       ;Load message addrinto IY
    CALL PrintStr           ;Print message
    CALL Input               ;Wait for user Input
    CALL OutputChar         ;Echo char
    CP 'R'
    ;JP Z,ReadDataFromFDDCMD
    CP 'W'
    ;JP Z,WriteDataToFDDCMD
    JP MainMenu          




;;Gets 4 digit hex number from user, stores in HL Destorys all registers
AskForHex:
        LD D,$04
AskForHexLoop:   
        CALL Input
        CALL OutputChar

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




StoreInRam:                     ;Store A into RAM at HL. This increments HL
        LD (HL),A               ;Load A into address HL points to
        INC HL                  ; INC HL to next address
        RET

;;Read data into ram starting at address HL from serial port, data len stored at DE
ReadDataLoop:
	CALL Input		            ; Read a byte from serial terminal
    CALL StoreInRam
    DEC DE                      ;decrement bytes left to read
    LD A,D                      ;ld highbyte of DE into A
    CP $00                      ;check if zero
	JP NZ, ReadDataLoop         ;if not keep looping
    LD A,E                      ;ld low byte of DE into A
    CP $00                      ;check if zero
    JP NZ, ReadDataLoop         ;if not keep looping
    RET



    .include messages.s


code_end:
        end