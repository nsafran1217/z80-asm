RAMSTART = $5000 
STACKADDR = $ffff

    .org $4000

Start:
    LD SP, STACKADDR
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
    .include commands.s

MainPrompt:

    LD B, $50               ;Text buffer is $40 and param buffer is $F. This covers both
    LD A, $00           
    LD HL, TextBuffer
ZeroTextBufferLoop:
    LD (HL), a
    INC HL
    DJNZ ZeroTextBufferLoop


    CALL PrintNewLine
    LD A, ":"
    CALL OutputChar
    LD HL, TextBuffer
    CALL ReadLine
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DisableRom:
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



;;;;;;;;;;;;;;;;
CMD_tbl:
    defb    "Q"
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
    defb    "{"
    defw    HDD_cmd
    defb    "F"
    defw    FDD_cmd
    defb    $00
    defw    InvalidCMD
tbl_end:

    .include messages.s

    defw    $0000       ;Some zeros to catch the backspace
TextBuffer:
    blk $40
ParamBuffer:
    blk $10

    .org $4ffe

    .word $0000