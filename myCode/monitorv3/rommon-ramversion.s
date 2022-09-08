RAMSTART = $5000 
DATALEN = $1000 ;4k bytes




    .org $4000

Start:
    LD SP,$ffff
    CALL SetupUART
    LD IY,splashScreen
    CALL PrintStr
    JP MainPrompt


    .include uart.s
    .include String.s
    .include hexout.s
    .include hexdump.s
    .include printregs.s
    .include ide.s




MainPrompt:
    CALL PrintNewLine
    LD A, ":"
    CALL OutputChar
    LD HL, TextBuffer
    CALL ReadLine
    CALL PrintNewLine
    CALL SkipSpace
    CALL ToUpper
    

    LD IY, CMD_tbl          ;Get command table addr
    LD B, A                 ;LD Command user entered into B
ParseLoop:
    LD A, (IY)              ;LD the command in table into A

    CP B                    ;Check if A contains the command user entered
    JP Z, CommandFound      ;If yes, jump out              
    CP $00                  ;Check if its a NUL
    JP Z, CommandFound      ;If it is, then we are at the end of the table
    INC IY                  ;No, INC to the next command
    INC IY
    INC IY

    JP ParseLoop            ;And keep looking

    LD A, "^"               ;Should never hit, remove THIS <----
    CALL OutputChar

CommandFound:               ;Valid command in B
    INC IY                  ;Get to command address
    LD C, (IY)              ;Put Address in BC
    INC IY
    LD B, (IY)
    PUSH BC                 ;Put it on the stack
    ;CALL PrintRegs
    RET                     ;jump to value on stack
    ;When we jump, HL is still pointing to the text buffer
    ;Each command will handle param parseing





    LD A, "#"               ;Should never hit, remove THIS <----
    CALL OutputChar





    JP MainPrompt            






;B 439B
;D 44A1 = jp 4375




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



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
    JP MainPrompt                 

LoadCMD4k:
    LD IY,loadMessage           ;Load message address into index register IY
    CALL PrintStr               ;Print the message
    LD HL, RAMSTART             ;Load starting ram address into HL
    LD DE, DATALEN              ;Load length of data into DE
    CALL ReadDataLoop
    JP MainPrompt

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
    JP MainPrompt

StartExecute4k:
    CALL PrintNewLine
    LD HL,RAMSTART          ;Set ram address back to start
    JP (HL)                 ;And start exectuon there

StartExecuteAddr:
    LD IY,WhatAddrMessage   
    CALL PrintStr 
    CALL AskForHex          ;Get addr from user
    CALL PrintNewLine
    JP (HL)                 ;And start exectuon there
ViewHexData:
        LD IY,WhatAddrMessage   
        CALL PrintStr 
        LD D,$04                ;Get 4 charcters
        CALL AskForHex      ;Get address from user
        CALL OutputHexData      ;output $80 data starting at HL
        JP MainPrompt

CPMCMD:
        ld	hl,4000h        ;Get CP/m Loader off disk and store in begining of RAM
        ld	bc,0000h
        ld	e,00h
        call 	disk_read
        jp	4000h           ;CP/M Loader that was just pulled off the disk



ResetCMD:
    JP $0000

DisableRomCMD:
        PUSH BC
        LD C,$70                ;Load disable rom address
        LD B,$01                ;Load disable rom bit
        OUT (C),B               ;send bit
        POP BC
        JP MainPrompt    
    
ReadDataFromHDDCMD:
        LD IY,ReadWriteDataToHDDMSG
        CALL PrintStr
        CALL AskForHex
        LD C,L
        CALL PrintNewLine
        CALL AskForHex
        LD B,L
        CALL PrintNewLine
        CALL AskForHex
        LD E,L
        CALL PrintNewLine
        CALL AskForHex
        CALL PrintNewLine
        CALL disk_read

        JP MainPrompt
WriteDataToHDDCMD:
        LD IY,AreYouSureMsg
        CALL PrintStr
        CALL InputChar
        CP "Y"
        JP NZ, MainPrompt
        LD IY,ReadWriteDataToHDDMSG
        CALL PrintStr
        CALL AskForHex
        LD C,L
        CALL PrintNewLine
        CALL AskForHex
        LD B,L
        CALL PrintNewLine
        CALL AskForHex
        LD E,L
        CALL PrintNewLine
        CALL AskForHex
        CALL PrintNewLine
        CALL disk_write
        JP MainPrompt



HDDMenu:
    LD IY,HDDMenuMSG       ;Load message addrinto IY
    CALL PrintStr           ;Print message
    CALL InputChar               ;Wait for user Input
    CALL OutputChar         ;Echo char
    CP "R"
    JP Z,ReadDataFromHDDCMD
    CP "W"
    JP Z,WriteDataToHDDCMD
    JP MainPrompt     

FDDMenu:
    LD IY,FDDMenuMSG       ;Load message addrinto IY
    CALL PrintStr           ;Print message
    CALL InputChar               ;Wait for user Input
    CALL OutputChar         ;Echo char
    CP "R"
    ;JP Z,ReadDataFromFDDCMD
    CP "W"
    ;JP Z,WriteDataToFDDCMD
    JP MainPrompt          




;;Gets 4 digit hex number from user, stores in HL Destorys all registers
AskForHex:
        LD D,$04
AskForHexLoop:   
        CALL InputChar
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
	CALL InputChar		            ; Read a byte from serial terminal
    CALL StoreInRam
    DEC DE                      ;decrement bytes left to read
    LD A,D                      ;ld highbyte of DE into A
    CP $00                      ;check if zero
	JP NZ, ReadDataLoop         ;if not keep looping
    LD A,E                      ;ld low byte of DE into A
    CP $00                      ;check if zero
    JP NZ, ReadDataLoop         ;if not keep looping
    ;call PrintRegs
    RET


    .org $4500
;;;;;;;;;;;;;;;;
CMD_tbl:
    defb    "B"
    defw    Beep_CMD
	defb	"D"
	defw	DUMP_cmd
	defb	"W"
	defw	WRITE_cmd
	defb	"R"
	defw	READ_cmd
	defb	"L"
	defw	LOAD_cmd
	defb	"B"
	defw	BOOT_cmd
	defb	"G"
	defw	GO_cmd
	defb	"I"
    defw    INio_cmd
    defb    "O"
    defw    OUTio_cmd
    defb    "H"
    defw    HELP_cmd
    defb    $00
    defw    InvalidCMD
tbl_end:


    .include commands.s

    .org $4700

    .include messages.s
    .org $4D00
TextBuffer:
    blk $40
    .include vars.s

    .org $4ffe

    .word $0000