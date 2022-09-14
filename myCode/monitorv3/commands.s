  





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
    CALL CheckIfHex
    JP C, DUMP_cmd_8Bit   ;If its not a carry flag, then we have valid hex to parse
    LD B, 1                 ;Prep to get one more byte
    INC IY
    CALL Parse_Param
    LD C, (IY)              ;Put ammount to dump in BC, 
    DEC IY
    LD B, (IY)              ;And next bit in B
    JP DUMP_cmd_LD_Addr
DUMP_cmd_8Bit:
    LD C, (IY)
    LD B, $00               ;Only 2 digits, so only load C with value              
DUMP_cmd_LD_Addr:
    DEC IY                  ;Put IY at sane position, 1st byte of address
    DEC IY
    LD H, (IY)
    INC IY
    LD L, (IY)              ;LD address to dump to into HL
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
    defw $0000



LOAD_cmd:                   ;Load data from serial port into specified memeory address of specified length`
    LD DE, $1000            ;Put defualt data length here incase we never get it
    CALL Check_Next_Param_Coming
    JP C, LOAD_cmd_Default
LOAD_cmd_Param
    LD B, 2                 ;Get 4 numbers
    LD IY, ParamBuffer
    CALL Parse_Param
    DEC HL                  ;Dec HL to space char or NUL
    CALL Check_Next_Param_Coming
    JP C, LOAD_cmd_defualtLen;If NUL, just dump default ammount
    INC IY                  ;If we have a vlue coming,
    INC IY                  ;Put IY to next free addres
    LD B, 2                 ;get 4 numbers
    CALL Parse_Param        ;IY is currently at second param
    LD D, (IY)              ;Put data len in DE 
    INC IY
    LD E, (IY)  
    DEC IY                  ;Put IY at sane position, 1st byte of address to load into
    DEC IY                  ;We dont need to do this if we only get 1 param
    DEC IY
LOAD_cmd_defualtLen:
    LD H, (IY)
    INC IY
    LD L, (IY)              ;LD address to load to into HL
    JP LOAD_cmd_ReadyToLoad
LOAD_cmd_Default:
    LD HL, RAMSTART                ;Load default address to put data to into HL
    LD IY, loadDefaultMessage
    CALL PrintStr
LOAD_cmd_ReadyToLoad:
    LD (AddressLoadedTo), HL
    LD IY,beginLoadMessage  ;Load message address into index register IY
    CALL PrintStr           ;Print the message
    CALL ReadDataLoop
    JP MainPrompt

AddressLoadedTo:
    defw RAMSTART


GO_cmd:                     ;Jump execution to specified address. Default to address we just loaded data to
    CALL Check_Next_Param_Coming
    JP C, GO_cmd_Default
GO_cmd_Param
    LD B, 2                 ;Get 4 numbers
    LD IY, ParamBuffer
    CALL Parse_Param
    LD H, (IY)
    INC IY
    LD L, (IY)              ;LD address to jump to into HL
    JP (HL)                 ;JP to it
GO_cmd_Default:
    LD HL, (AddressLoadedTo)
    JP (HL)




INio_cmd:                       ;read value from specified IO port and display it
    CALL Check_Next_Param_Coming
    JP C, InvalidCMD            ;If a param isnt coming, then just exit. we need params
    LD B,1
    LD IY, ParamBuffer
    CALL Parse_Param
    LD C, (IY)                  ;Param buffer is pointing at the value we want
    LD IY, iPrompt              ;Reprint prompt to screen
    CALL PrintStr
    LD A, C                     ;Reprint port we are reading
    CALL hexout
    CALL PrintSpace
    IN A, (C)                   ;Read the value
    CALL hexout
    JP MainPrompt

OUTio_cmd:                      ;write value to specified IO port
    CALL Check_Next_Param_Coming
    JP C, InvalidCMD            ;If a param isnt coming, then just exit. we need params
    LD B, 1
    LD IY, ParamBuffer
    CALL Parse_Param
    DEC HL
    CALL Check_Next_Param_Coming
    JP C, InvalidCMD
    INC IY
    LD B, 1
    CALL Parse_Param
    LD C, (IY)
    DEC IY
    LD A, (IY)
    OUT (C),A
    JP MainPrompt


HDD_cmd:
FDD_cmd:
    JP MainPrompt
BOOT_cmd:

CPMCMD:
    ld hl,RAMSTART        ;Get CP/m Loader off disk and store in begining of RAM
    ld bc,0000h
    ld e,00h
    call disk_read
    jp RAMSTART          ;CP/M Loader that was just pulled off the disk

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





