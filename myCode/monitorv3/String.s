;String Helper

;Print a string indexed in IY
;Must be NUL terminated (.asciiz)
PrintStr: 
        PUSH AF
PrintStrLoop:
        LD A,(IY)               ;LD into A value at address in IY
        CALL OutputChar         ;Output A
        INC IY                  ;INC IY, which is incrementing the address of the message
        LD A,(IY)               ;LD into A the next char to be printed
        CP $00                  ;Check if that char is 0. CP subtracts value from A but doesnt chnage A, only updates flags
        JP NZ,PrintStrLoop          ;If its not 0, go back to Alert and continue printing
        POP AF
        RET
;Print NewLine to serial     
PrintNewLine:
    PUSH IY
    LD IY,CRLF
    CALL PrintStr
    POP IY
    RET

;Conver char in A to uppercase
ToUpper:
    CP 'a'
    RET C
    CP 'z'
    RET NC
    LD B, $20
    SUB B
    RET

 
;IN    HL     Address of string1.
;      DE     Address of string2.
;OUT   zero   Set if string1 = string2, reset if string1 != string2.
;      carry  Set if string1 > string2, reset if string1 <= string2.
;from https://tutorials.eeems.ca/ASMin28Days/lesson/day16.html#cmp
CmpStrings:
    PUSH   HL
    PUSH   DE

    LD     A, (DE)          ; Compare lengths to determine smaller string
    CP     (HL)            ; (want to minimize work).
    JR     C, Str1IsBigger
    LD     A, (HL)

Str1IsBigger:
    LD     C, A             ; Put length in BC
    LD     B, 0
    INC    DE              ; Increment pointers to meat of string.
    INC    HL

CmpLoop:
    LD     A, (DE)          ; Compare bytes.
    CPI
    JR     NZ, NoMatch      ; If (HL) != (DE), abort.
    INC    DE              ; Update pointer.
    JP     PE, CmpLoop

    POP    DE
    POP    HL
    LD     A, (DE)          ; Check string lengths to see if really equal.
    CP     (HL)
    RET

NoMatch:
    DEC    HL
    CP     (HL)            ; Compare again to affect carry.
    POP    DE
    POP    HL
    RET

 CRLF:           .asciiz     "\r\n"