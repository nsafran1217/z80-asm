  





;Number of 8 bit params to get in B
;Address to text buffer in HL
;Address of number value in IY
;Returns IY with address to number in it
;Returns HL with address of next char to read in text buffer
;Destroys AF, BC
Parse_Param:                
    CALL SkipSpace
    PUSH IY
Parse_Param_Loop:
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
    DJNZ Parse_Param_Loop;Do this until we get all the numbers
    POP IY
    RET

Check_Next_Param_Coming:    ;Check if value in HL is a space or a NUL, if not, error. Carry flag if NUL THis skips the space in param list, so you dont have to
                            ;Assumes we are at char before the space if a param is coming, or char before nul
    INC HL
    LD A, (HL)              ;If this is a space we know a value is coming
    CP " "
    RET Z                   ;Return if its a space
    LD A, (HL)
    CP $01                  ;Check if its NUL be CP 1, this will set Carry flag
    RET C
    JP InvalidCMD           ;Else, print error message


DUMP_cmd:
    CALL Check_Next_Param_Coming
    JP C, DUMP_cmd_Next
DUMP_cmd_Param
    LD B, 2                 ;Get 4 numbers
    LD IY, ParamBuffer
    CALL Parse_Param
    DEC HL                  ;Dec HL to space char or NUL
    CALL Check_Next_Param_Coming
    JP C, DUMP_cmd_defualt  ;If NUL, just dump default ammount
    INC IY                  ;If we have a vlue coming,
    INC IY                  ;Put IY to next free addres
    LD B, 1                 ;And get 2 numbers
    CALL Parse_Param
    ;;we want to check if its a 16 bit number or a 8 bit number. so check if next value is valid hex, then parse it into IY
    LD A, (HL)
    LD B, 1                 ;Prep to get one more byte
    INC IY
    LD (IY), 0              ;Put 0 just incase its not vale
    CALL CheckIfHex
    CALL NC, Parse_Param    ;If its not a carry flag, then we have valid hex to parse
    LD C, (IY)              ;Put ammount to dump in B, this will be 0 if its 2 bytes
    DEC IY
    LD B, (IY)              ;And next bit in C
    DEC IY                  ;Put IY at sane position, 1st byte of address
    DEC IY
    LD H, (IY)
    INC IY
    LD L, (IY)              ;LD address to dump to into HL
    CALL PrintRegs
    JP DUMP_cmd_OUT

DUMP_cmd_Next:              ;Dump next section of memory
    LD HL, (LastAddrDump)
    LD B, $01
    LD C, $00
    ADD HL,BC 
   ; DEC HL
    JP DUMP_cmd_OUT

DUMP_cmd_defualt:           ;Dump defualt amount
    LD B, $01
    LD C, $00               ;$100 is the default ammount to dump
    LD H, (IY)
    INC IY
    LD L, (IY)              ;LD address to dump to into HL

DUMP_cmd_OUT:

    LD (LastAddrDump), HL
    CALL OutputHexDumpTable
    JP MainPrompt

LastAddrDump:
    defw $0000


WRITE_cmd:                  ;Write value entered to address entered. If address isnt entered, use the last address written
    CALL Check_Next_Param_Coming
    JP C, InvalidCMD        ;If its a NUL, then its just a w with not value, not valid

WRITE_cmd_Param:
    LD B, 1                 ;Only get 1 8bit value
    LD IY, ParamBuffer      ;LD place to store params, first bit is value. next 2 bits is address
    CALL Parse_Param        ;Address to value is in (IY)
    DEC HL                  ;Put TextBuffer back to before param starts
    CALL Check_Next_Param_Coming
    JP C, WRITE_cmd_Next    ;If its a NUL, carry is set and we just write to next addr
    INC IY                  ;INC IY so we put address next to value to write
    LD B, 2                 ;we want a 16 bit value, so get 4 numbers
    CALL Parse_Param        ;Text buffer should be in the correct place
    DEC IY                  ;Get back to value in paramBuffer
    LD A, (IY)              ;Put into A
    INC IY
    LD H, (IY)
    INC IY
    LD L, (IY)              ;LD address to write to into HL
    JP WRITE_cmd_OUT

WRITE_cmd_Next:
    LD A, (IY)
    LD HL, (LastAddrWrite)
    INC HL  
WRITE_cmd_OUT:
    LD (HL), A              ;Write value to addr in HL
    LD (LastAddrWrite), HL

    JP MainPrompt

LastAddrWrite:
    defw    $0000


READ_cmd:                   ;Read address entered and print value to screen. $store last addr and print next value if entered with no params
    CALL Check_Next_Param_Coming
    JP C, READ_cmd_Next
READ_cmd_Param:
    LD B, 2                 ;Only get 2 8bit values
    LD IY, ParamBuffer
    CALL Parse_Param        ;Address to numbers we want is in (iY)
    LD H, (IY)
    INC IY
    LD L, (IY)              ;Transfer number we want into HL
    JP READ_cmd_Out
READ_cmd_Next:
    LD HL, (LastAddrRead)
    INC HL  
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





