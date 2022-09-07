

    .org $4000

Start:
    LD SP,$ffff
    LD IY,splashScreen
    CALL PrintStr
    JP CommandPrompt


    .include uart.s
    .include String.s
    .include hexout.s
    .include hexdumptest.s



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;Command number to execute is in A
CommandExecute:
    CALL hexout
    CALL NewLine
    CP $00
    JP Z, HelpCMD
    CP $02
    JP Z, ReadCMD
    CP $04
    JP Z, WriteCMD
    CP $06
    JP Z, BeepCMD
    CP $08
    JP Z, ResetCMD
    CP $0A
    JP Z, LoadCMD
    JP CommandPrompt

HelpCMD:
    LD IY, HelpMSG
    CALL PrintStr
    CALL PrintRegs
    JP CommandPrompt
ReadCMD:
    CALL ViewHexDataTest
    JP CommandPrompt
WriteCMD:

LoadCMD:   

    LD IY, ARGS         ;LD the pointer to the arg string
    LD IX, $0000
    LD E, 0             ;Keep track of what arg we are doing
ParseArgsLoadCMD:
    INC E               ;1C, trigger on this for analyzer
    LD A, E
    CP $03
    JP Z, InvalidArgLenth
CheckLoadedArgLen:
    LD D, 5             ;we want 4 characters in the arg
    LD A, (IY)          ;Load first arg char, should be $20
    CP $00              ;If its NUL, then there are no args
    JP Z, LoadCMDNoArgs
    
CheckLoadedArgLenLoop:
    INC IY              ;Then we just inc to non space char and loop through counting
    DEC D               
    LD A, (IY)          ;Load char into A
    CP $20              ;Is it a space?
    JP Z, CheckLoadedArgLenSpaceOrNULHit
    CP $00              ;Is it a NUL?
    JP Z, CheckLoadedArgLenSpaceOrNULHit

    JP CheckLoadedArgLenLoop   ;just keep looping, when we hit a delim, we jump


CheckLoadedArgLenSpaceOrNULHit: ;need to check we got 4 chars and determine if we need to get second arg
    LD A,D
    CP $00
    JP NZ, InvalidArgLenth
    LD A, E                 ;E is num of arg counters, we only want 2

    CP $02              ;So we will jump out if we have 2 at this point. If we had a space, we already check if theres 2 up in checkloadedarglen. we shouldnt ever hit this with anything but a NUL as the next char
    JP Z, LoadCMDTwoArgs    
    LD A, (IY)
    CP $20                  ;If next char is a space, we need another arg
    JP NZ, LoadCMDOneArg



    PUSH IY              ;store this pointer in IX for use later. This will be the first arg
    POP IX
    DEC IX                  ;Put IX back to beginning of pointer
    DEC IX
    DEC IX
    DEC IX
    JP ParseArgsLoadCMD
    


InvalidArgLenth:
    LD A, '%'
    CALL OutputChar
    LD IY, ARGS
    CALL PrintStr
    JP CommandPrompt

InvalidArgument:
    LD A, '*'
    CALL OutputChar
    LD IY, ARGS
    CALL PrintStr
    JP CommandPrompt


LoadCMDNoArgs:

    JP CommandPrompt

;One arg, load at address in arg1 and 4k bytes ($1000 bytes)
LoadCMDOneArg:                  ;pointer to arg string is at IX
        LD A, '@'
    CALL OutputChar
    PUSH IX                     ;move IX to IY
    POP IY
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    CALL PointerToValue16       ;With this my value is at HL

    LD DE, $1000                ;Load length of data into DE
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    CALL ReadDataLoop
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    JP CommandPrompt

LoadCMDTwoArgs:                 ;pointer to first arg is at IX, second is at IY
        LD A, '#'
    CALL OutputChar
    CALL PointerToValue16       ;This will get the data len from IY and store at HL
    PUSH HL                     ;Push Datalen to stack to get later
    PUSH IX                     ;Move IX to IY
    POP IY
    CALL PointerToValue16       ;Get data addr to HL

    POP DE                      ;Get data len out of stack
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    CALL ReadDataLoop
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
    JP CommandPrompt

;;Take 16 bit number stored in ascii at memory location IY and convert to number, store result in HL, dont change memory
PointerToValue16:
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    PUSH IY
    LD D,$04            ;Number of numbers we need to get
PointerToValue16Loop:
    LD A, (IY)              ;get the char
    INC IY


    CALL ATOHEX             ;Convert hex ascii to real number
    
    PUSH AF                 ;push value to stack
    DEC D                   ;Dec char counter
    LD A,D                  ;Move D to A
    CP $00                  ;Is 0?
    JP NZ,PointerToValue16Loop ;Keep going if we need more CHARS
    POP BC                  ;get low nibble
    ;LD B,A                  ;put into B
    POP AF                  ;get high nibble
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    RLC A                   ;shift nibble left 4 times
    RLC A
    RLC A
    RLC A
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    OR B                    ;or with low nibble
    LD L,A                  ;load low byte
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

    POP BC
    ;LD B,A
    POP AF
    RLC A
    RLC A
    RLC A
    RLC A
    OR B
    LD H,A                  ;load high byte 
    POP IY
    CALL PrintRegs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    RET


BeepCMD:
    LD A, $07                   ;Bell character
    CALL OutputChar
    JP CommandPrompt

ResetCMD:
    JP $0000

CommandPrompt:  
        LD A, ':'
        CALL OutputChar
        LD HL, COMMAND          ;Load address of command word into HL and DE
        LD IX, COMMAND          ;IX is pointer to length of string, HL is pointer to char
        LD (IX), 0              ;Set length to zero
        INC HL                  ;Put HL at first char location
        
CommandPromptLoop:

        CALL Input              ;Wait for user Input
        CALL OutputChar         ;Echo char
        CP $0D                  ;CR
        JP Z, CommandParse      ;If CR, go to command parse
        CP $08                  ;If BS, go to backspace
        JP Z, BackSpace               
        LD (HL), A              ;Else put char in memory
        INC HL                  ;Advance to next char memory
        INC (IX)                ;INC number of characters

        JP CommandPromptLoop

;Compare HL and DE 16 bit numbers. Z is set if equal
;CP16bit:
;    LD A, H
;    LD B, D
;    CP B
;    RET NZ
;    LD A, L
;    LD B, E
;    CP B
;    RET

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
    call PrintRegs
    RET




CommandParse:
    LD A, $00               ;NUL
    LD (HL), A              ;NUL terminate the command entered
    CALL NewLine
    LD A, (COMMAND)
    CP $00                  ;If not chars in counter
    JP Z, CommandPrompt     ;Go Back to prompt
    ;Next, we need to seperate the args from the command entered. Args are seperated from command with a space. 
DelimitCommand:
    LD IY,COMMAND           ;Load address of command into IY
    LD (IX), $ff             ;Reset Count of Chars, we will set this equal to length of command word. We want this to overflow to 0
DelimitCommandLoop:  
    INC IY                  ;Advance pointer to char
    INC (IX)                ;Add count of characters
    LD A, (IY)              ;LD A with val of IY, char of command
    CP $00                  ;Check if we hit a NUL so it doesnt go forever
    JP Z, ContinueParseCommand
    CP $20                  ;Space
    JP NZ, DelimitCommandLoop ;If it is not a space, keep searching for a space

      
;IY contains pointer to the first space
MoveArgs:
    LD IX, ARGS
    DEC IY
MoveArgsLoop:
    INC IY                  ;Next char
    LD A,(IY)               ;LD into A value at address in IY
    LD (IX), A              ;LD A into new pointer
    INC IX                  ;next pointer
    CP $00                  ;Did we hit the NUL?
    JP NZ, MoveArgsLoop


ContinueParseCommand:
    LD DE,00                ;Number of the command we are testing, though each command is 2 numbers. 1st is 0, 2nd is 2, 3rd is 4, 4th is 6, etc...

CommandParseLoop:
    LD HL,AvalCommands      ; put into HL location of command locations
    ADD HL, DE              ; inc HL to command we are testing
    PUSH HL                 ;Store HL
    LD A, (HL)              ;LD A with value at HL
    CP $00                  ;Check if 0
    JP NZ, ContinueParse    ;If not, keep going
    INC HL                  ;need to check other nybble
    LD A, (HL)          
    CP $00
    JP NZ, ContinueParse    
    POP HL                  ;If this nybble is also zero, pop HL(Cleanup stack)
    JP InvalidCommand       ;JP

ContinueParse:
    POP HL
    PUSH DE                 ;store number command we are testing
    LD E, (HL)              ; put high nybble into E from address of command
    INC HL                  ;to low nybble
    LD D, (HL)              ;ld low nybble
    LD HL, COMMAND          ;put command to compare addr in hl
    CALL CmpStrings
    POP DE                  ;Get num of command we are testing

    JP Z, CommandMatch      ;If strings match, jump
    INC DE                  ; inc de to next number command to test
    INC DE
    JP CommandParseLoop     ;and do it again
    


    
CommandEcho:    
    LD HL,COMMAND       ;ld address of command
    LD D, (HL)              ;load length of string into d
    INC HL                  ;inc to first char
CommandEchoLoop:
    LD A,(HL)               ;ld first char
    CALL OutputChar         ;output it
    INC HL                  ;next char
    DEC D                   ;dec number of chars left to print
    LD A,D                  ;see if num of chars is 0
    CP $00
    JP NZ, CommandEchoLoop  ;if not zero, loop
    CALL NewLine            ;else, print new line
    JP CommandPrompt

;;command number should be in DE [E] at this point
CommandMatch:   ;;for testing
    LD A, 'O'
    CALL OutputChar
    LD A, 'k'
    CALL OutputChar
    CALL NewLine
    LD A,E                  ;Put num of command in A
    JP CommandExecute
    ;JP CommandEcho

InvalidCommand:
    LD IY,InvalidCommandMSG
    CALL PrintStr
    JP CommandEcho

BackSpace:
    ;PUSH HL                 ;HL is pointing to char in front of the one we want to delete
    ;LD HL, COMMAND          ;Now to string we are editing
    ;LD D, (HL)
    LD A,(IX)               ;Get number of chars in string
    CP $00                  ;If chars in counter
    JP NZ, DelChar          ;Jump to DelChar
    LD A, $1B               ;ANSI Escape
    CALL OutputChar
    LD A, '['
    CALL OutputChar
    LD A, 'C'               ;Move cursor right since nothing was deleted
    CALL OutputChar
    ;POP HL
    JP CommandPromptLoop
 
DelChar:
    
    ;LD HL, COMMAND;Should already have this in HL
    DEC (IX)                ;decrementing number of chars in string

    LD A, $1B               ;ANSI Escape
    CALL OutputChar
    LD A, '['
    CALL OutputChar
    LD A, 'K'               ;Erase Line
    CALL OutputChar
    ;POP HL
    DEC HL                  ;Move HL to point to last char we entered. WIll just overwrite
    JP CommandPromptLoop




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;Lets try something new again. I dont like the stuff below. Its dumb

    .org $4400
COMMAND:
    blk $40
ARGS:
    blk $40

;Lets try something new. Create a few different arg variables
;    .org $4400
;CURRENTSTRINGPOINTER: defw $0000    ;Pointer to current string being modified
    ;.org $4410
;COMMANDWORD:    blk 64   ;63 chars max command length, All are length prefixed
;ARG1:           blk 64   ;$40
;ARG2:           blk 64
;ARG3:           blk 64

AvalCommands:
    defw    (HELP)      ;0
    defw    (READ)      ;2
    defw    (WRITE)     ;4
    defw    (BEEP)      ;6
    defw    (RESET)     ;8
    defw    (LOAD)      ;0A
    defw    $0000


HELP:   defb    4       ;Length of string
HELPTEXT:    .ascii  "HELP" ;not NUL terminated
READ:   defb    4
READTEXT:    .ascii  "READ"
WRITE:  defb    5
WRITETEXT:   .ascii  "WRITE"
BEEP:   defb    4
BEEPTEXT:    .ascii  "BEEP"
RESET:   defb    5
RESETTEXT:    .ascii  "RESET"
LOAD:   defb    4
LOADTEXT:    .ascii  "LOAD"


    .include messages.s


    

PrintRegs:
    PUSH BC
    PUSH DE
    PUSH IY
    PUSH IX
    PUSH HL
    PUSH AF
    LD A, 'A'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    POP AF
    PUSH AF
    CALL hexout
        LD A, ' '
    CALL OutputChar

    LD A, 'B'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    LD A, B
    CALL hexout
        LD A, ' '
    CALL OutputChar

    LD A, 'C'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    LD A, C
    CALL hexout
        LD A, ' '
    CALL OutputChar

    LD A, 'D'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    LD A, D
    CALL hexout
        LD A, ' '
    CALL OutputChar

    LD A, 'E'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    LD A, E
    CALL hexout
        LD A, ' '
    CALL OutputChar

    LD A, 'H'
    CALL OutputChar
    LD A, 'L'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    LD A, H
    CALL hexout
    LD A, L
    CALL hexout
        LD A, ' '
    CALL OutputChar

    LD A, 'I'
    CALL OutputChar
    LD A, 'X'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    LD A, IXH
    CALL hexout
    LD A, IXL
    CALL hexout
        LD A, ' '
    CALL OutputChar

    LD A, 'I'
    CALL OutputChar
    LD A, 'Y'
    CALL OutputChar
    LD A, ':'
    CALL OutputChar
    LD A, IYH
    CALL hexout
    LD A, IYL
    CALL hexout
        LD A, ' '
    CALL OutputChar


    POP AF
    POP HL
    POP IX
    POP IY
    POP DE
    POP BC

    CALL NewLine

    RET


    .org $4ffe

    .word $0000