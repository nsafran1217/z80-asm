;Subroutines to print out strings to the iv17 display
;Scrolling, static printing, etc

PortACMD    = $52
PortAData   = $50
NumOfVFDTubes = 8

InputChar   = $0035
OutputChar  = $0038
PrintStr    = $003B
Start       = $0040




    .org $4000

    CALL InitPortA
    LD HL, TestMessage
    CALL BlankDisplay
    CALL ShiftOutStringTubeLen
    JP Start


BlankDisplay:
    PUSH BC
    PUSH AF
    LD B, NumOfVFDTubes   ;Number of blanks to shift out
    LD A, 0
BlankDisplayLoop:
    CALL ShiftOutChar
    DJNZ BlankDisplayLoop
    CALL StrobeDisplay      ;Strobe when done
    POP AF
    POP BC
    RET

;Shift out string equal to number of tubes. 
;Provide HL pointing to beginning of string
;Will move right = to number of tubes in memory
;Will shift out right to left
ShiftOutStringTubeLen:
    PUSH AF
    PUSH BC
    LD B, NumOfVFDTubes-1
ShiftOutStringTubeLenLoop1:
    INC HL
    DJNZ ShiftOutStringTubeLenLoop1
    LD B, NumOfVFDTubes
ShiftOutStringTubeLenLoop2:
    LD A, (HL)
    DEC HL
    CALL ShiftOutChar
    DJNZ ShiftOutStringTubeLenLoop2

    CALL StrobeDisplay
    POP BC
    POP AF
    RET


;Shift out NULL terminatedstring pointed to by HL
;Destroys HL
ShiftOutStringNULTerm:
    PUSH AF
    PUSH BC
    LD B, 0
    ;Get to end of string (CP 0)
    ;Record this length
    ;Then we decrement through it
    ;shift out each character as we go.
    ;Will be aligned to the left of the display
    ;Would be way easier to scroll if I designed the hardware to shift in from the right to left...

FindEndLoop:
    INC HL
    INC B                   ;Length of the string
    LD A, (HL)
    CP 0
    JP NZ, FindEndLoop
ShiftOutStringLoop:
    DEC HL                  ;First character to shift out
    LD A, (HL)              ;Grab char
    CALL ShiftOutChar       ;shift it out
    DJNZ ShiftOutStringLoop ;Keep going until we have sent all chars

    CALL StrobeDisplay             ;Done, strobe the dispaly
    POP BC
    POP AF
    RET


TestMessage: .asciiz "Test Long String"


    .include iv17.s
    .org $4A00
    .include iv17asciitable.s

    ;Padding
    .org $4ffe
    .word $0000