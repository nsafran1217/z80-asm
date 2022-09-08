    .org $4600
DUMP_cmd:
    LD A, "d"
    CALL OutputChar
    JP MainPrompt
WRITE_cmd:
    LD A, "w"
    CALL OutputChar
    JP MainPrompt 



READ_cmd:                   ;Read address entered and print value to screen. $store last addr and print next value if entered with no params
    INC HL                  ;If this is a space we know a value is coming
    LD A, (HL)
    CP " "
    JP Z, READ_cmd_Param
    CP $00                  ;If its NUL, then we just read the next addr
    JP Z, READ_cmd_Next
    JP InvalidCMD           ;Else, print error message

    
READ_cmd_Next:
    LD HL, (LastAddrRead)
    INC HL
    JP READ_cmd_Out

READ_cmd_Param:
    LD B, 2                 ;Only get 4 characters
READ_cmd_Param_Loop:
    INC HL
    LD A, (HL)              ;Put next char of param in A
    CALL CheckIfHex         ;If its Hex, convert it
    JP C, InvalidCMD        ;If its not hex, exit with error
    RLA
    RLA
    RLA
    RLA
    LD C, A
    INC HL
    LD A, (HL)              ;Put next char of param in A
    CALL CheckIfHex         ;If its Hex, convert it
    JP C, InvalidCMD        ;If its not hex, exit with error
    OR C                    ;Combine with first nibble
    PUSH AF
    DJNZ READ_cmd_Param_Loop;Do this twice, then continue
    POP AF
    LD L, A
    POP AF
    LD H, A
READ_cmd_Out:
    LD (LastAddrRead), HL
    LD A, (HL)
    CALL hexout
    CALL PrintNewLine
    JP MainPrompt
LastAddrRead:
    defw    $0000












LOAD_cmd:
    LD A, "l"
    CALL OutputChar
    JP MainPrompt
BOOT_cmd:
    LD A, "b"
    CALL OutputChar
    JP MainPrompt
GO_cmd:
    LD A, "g"
    CALL OutputChar
    JP MainPrompt
INio_cmd:
    LD A, "i"
    CALL OutputChar
    JP MainPrompt
OUTio_cmd:
    LD A, "o"
    CALL OutputChar
    JP MainPrompt
HELP_cmd:
    LD A, "h"
    CALL OutputChar
    JP MainPrompt

Beep_CMD:
    LD A, $07                   ;Bell character
    CALL OutputChar
    JP MainPrompt

InvalidCMD:
    LD IY, InvalidCMDMsg
    CALL PrintStr
    JP MainPrompt