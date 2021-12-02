RAMSTART = $5000 
DATALEN = $1000 ;4k bytes




    .org $4000

Start:
    LD SP,$ffff
    LD IY,TestLoadMsg
    CALL PrintStr
    JP CommandPrompt


    .include uart.s
    .include String.s
    .include hexout.s
    .include hexdumptest.s

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


HelpCMD:
    LD IY, HelpMSG
    CALL PrintStr
    JP CommandPrompt
ReadCMD:
    CALL ViewHexDataTest
    JP CommandPrompt
WriteCMD:

BeepCMD:
    LD A, $07                   ;Bell character
    CALL OutputChar
    JP CommandPrompt

ResetCMD:
    JP $0000

CommandPrompt:  
        LD A, ':'
        CALL OutputChar
        LD HL, COMMANDWORD      ;Load address of command word into HL
        LD (HL), 0              ;Set length to zero
        LD (CURRENTSTRINGPOINTER), HL   ;And store as the current string being modified
        INC HL                  ;Put HL at first char location
        

        ;LD HL,COMMANDSTRING     ;Location of string, length prefixed
        ;LD (HL),0               ;Number of characters counter   
        ;LD D, H                 ;Put address of string into DE
        ;LD E, L
        ;INC DE                  ;And put it at first char location
CommandPromptLoop:

        CALL Input              ;Wait for user Input
        CALL OutputChar         ;Echo char
        CP $0D                  ;CR
        JP Z, CommandParse      ;If CR, go to command parse
        CP $5C                  ;\
        JP Z, CommandDelimit    ;\ entered
        CP $08                  ;If BS, go to backspace
        JP Z, BackSpace               
        LD (HL), A              ;Else put char in memory
        INC HL                  ;Advance to next char memory
        PUSH HL                 ;Store address to put next char
        LD HL,(CURRENTSTRINGPOINTER)     ;LD Current string being modified
        INC (HL)
        POP HL


        JP CommandPromptLoop

CommandDelimit:

    LD HL, (CURRENTSTRINGPOINTER)

    LD DE, COMMANDWORD        ;Check what string we are pointing to
    CALL CheckArg
    
    JP Z, ContinueDelimitArg1
    LD DE, ARG1
    CALL CheckArg
    JP Z, ContinueDelimitArg2
    LD DE, ARG2
    CALL CheckArg
    JP Z, ContinueDelimitArg3
    LD DE, ARG3
    CALL CheckArg
    JP Z, ContinueDelimitArgsFull
ContinueDelimitArg1:
    LD DE, ARG1
    JP ContinueDelimit
ContinueDelimitArg2:
    LD DE, ARG2
    JP ContinueDelimit
ContinueDelimitArg3:
    LD DE, ARG3
    JP ContinueDelimit
ContinueDelimitArgsFull:
    
ContinueDelimit:
    LD (CURRENTSTRINGPOINTER), DE   ;Change pointer to new arg we are looking at
    LD HL, (CURRENTSTRINGPOINTER)   ;And put in HL for use
    LD (HL), 1                  ;First byte is length, which will be 1
    INC HL                      ;go to char
    LD (HL), $5C                ;and put a backslash\
    INC HL

    ;LD H, D                 ;Move pointer to arg length char
    ;LD L, E
    ;LD (HL), 1              ;And set it to 1. It will be INCed in the main loop
    ;LD (DE), A              ;And store delmiter just after the length
    JP CommandPromptLoop

;Arg address to check 
CheckArg:
    LD A, H
    LD B, D
    CP B
    RET NZ
    LD A, L
    LD B, E
    CP B
    RET

CommandParse:
    CALL NewLine
    LD A, (COMMANDWORD)
    CP $00                  ;If not chars in counter
    JP Z, CommandPrompt     ;Go Back to prompt

    LD DE,00                ;Number of the command we are testing, though each command is 2 numbers. 1st is 0, 2nd is 2, 3rd is 4, 4th is 6, etc...

CommandParseLoop:
    LD HL,Commands          ; put into HL location of command locations
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
    LD HL, COMMANDWORD    ;put command to compare addr in hl
    CALL CmpStrings
    POP DE                  ;Get num of command we are testing

    JP Z, CommandMatch      ;If strings match, jump
    INC DE                  ; inc de to next number command to test
    INC DE
    JP CommandParseLoop     ;and do it again
    


    
CommandEcho:    
    LD HL,COMMANDWORD       ;ld address of command
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
;;Command number to execute is in A
CommandExecute:
    CALL hexout
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
    JP CommandPrompt


BackSpace:
    PUSH HL                 ;HL is pointing to char in front of the one we want to delete
    LD HL,(CURRENTSTRINGPOINTER);Now to string we are editing
    ;LD D, (HL)
    LD A,(HL)               ;Get number of chars in string
    CP $00                  ;If chars in counter
    JP NZ, DelChar          ;Jump to DelChar
    LD A, $1B               ;ANSI Escape
    CALL OutputChar
    LD A, '['
    CALL OutputChar
    LD A, 'C'               ;Move cursor right since nothing was deleted
    CALL OutputChar
    POP HL
    JP CommandPromptLoop
 
DelChar:
    
    LD HL, (CURRENTSTRINGPOINTER)
    DEC (HL)                ;decrementing number of chars in string

    LD A, $1B               ;ANSI Escape
    CALL OutputChar
    LD A, '['
    CALL OutputChar
    LD A, 'K'               ;Erase Line
    CALL OutputChar
    POP HL
    DEC HL                  ;Move HL to point to last char we entered. WIll just overwrite
    LD A, (HL)              ;Get char that we want to delete
    CP $5C                  ;IF it is a \
    JP Z, DelDelimiter      ;Delete the delimiter and change current string pointer
    JP CommandPromptLoop



DelDelimiter:               ;My issue is somewhere in here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    LD DE, (CURRENTSTRINGPOINTER)
    LD HL, ARG1        ;Check what string we are pointing to
    CALL CheckArg

    JP Z, ContinueDELDelimitArg1
    LD HL, ARG2
    CALL CheckArg
    JP Z, ContinueDELDelimitArg2
    LD HL, ARG3
    CALL CheckArg
    JP Z, ContinueDELDelimitArg3
    JP CommandPromptLoop

ContinueDELDelimitArg1:
    LD HL, COMMANDWORD
    JP ContinueDELDelimit
ContinueDELDelimitArg2:
    LD HL, ARG1
    JP ContinueDELDelimit
ContinueDELDelimitArg3:
    LD HL, ARG2

ContinueDELDelimit:
    LD (CURRENTSTRINGPOINTER), HL   ;set current string to HL
    LD A, (HL)                      ;Get length of string in HL
    LD D, 0                         ;Nothing in high byte
    LD E, A                         ;ld low byte in E
    ADD HL, DE                      ;Add num of chars to HL so it points to end of string
    INC HL
    JP CommandPromptLoop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





TestLoadMsg:    .asciiz     "\r\n\r\nStart Test\r\n\r\n"

InvalidCommandMSG:  .asciiz "\r\nInvalid Command -- "

HelpMSG:        .asciiz "\r\nValid Commands. Use all CAPS.\r\nHELP -- Display this message\r\nREAD -- Read value\r\nWRITE -- Write Value\r\nBEEP -- Beep\r\nRESET -- JP to $0000\r\n"


;;Lets try something new again. I dont like the stuff below. Its dumb


;Lets try something new. Create a few different arg variables
    .org $4400
CURRENTSTRINGPOINTER: defw $0000    ;Pointer to current string being modified
    .org $4410
COMMANDWORD:    blk 64   ;63 chars max command length, All are length prefixed
ARG1:           blk 64   ;$40
ARG2:           blk 64
ARG3:           blk 64

Commands:
    defw    (HELP)      ;0
    defw    (READ)      ;2
    defw    (WRITE)     ;4
    defw    (BEEP)      ;6
    defw    (RESET)     ;8
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



    .org $4ffe

    .word $0000