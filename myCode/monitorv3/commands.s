  
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
    LD B, 2                 ;Only get 2 8bit values
    LD IY, ParamBuffer
    CALL Parse_Param        ;Address to numbers we want is in (iY)
    LD H, (IY)
    INC IY
    LD L, (IY)              ;Transfer number we want into HL
READ_cmd_Out:
    LD IY, rPrompt          ;Reprint prompt to screen
    CALL PrintStr
    LD A, H
    CALL hexout
    LD A, L
    CALL hexout             ;print address we are reading
    CALL PrintSpace
    LD (LastAddrRead), HL
    LD A, (HL)  
    CALL hexout             ;And print value we want
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
    LD IY, HelpMSG
    CALL PrintStr
    JP MainPrompt

Beep_CMD:
    LD A, $07                   ;Bell character
    CALL OutputChar
    JP MainPrompt

InvalidCMD:
    LD SP, STACKADDR            ;Reset the stack. Assume values on it are bad
    LD IY, InvalidCMDMsg
    CALL PrintStr
    JP MainPrompt               ;Just go back to the menu






;Number of 8 bit params to get in B
;Address to text buffer in HL
;Address of number value in IY
;Returns IY with address to number in it
;Destroys AF, BC, HL
Parse_Param:                
    CALL SkipSpace
    PUSH IY
READ_cmd_Param_Loop:
    LD A, (HL)              ;Put next char of param in A
    CALL CheckIfHex         ;If its Hex, convert it
    JP C, InvalidCMD        ;If its not hex, print error message and go back to menu
    RLA
    RLA
    RLA
    RLA
    LD C, A                 ;Put shifted 4bit value in C
    INC HL
    LD A, (HL)              ;Put next char of param in A
    CALL CheckIfHex         ;If its Hex, convert it
    JP C, InvalidCMD        ;If its not hex, exit with error
    OR C                    ;Combine with first nibble
    LD (IY), A              ;Put Value in address
    INC IY
    INC HL
    DJNZ READ_cmd_Param_Loop;Do this until we get all the numbers
    POP IY
    RET

