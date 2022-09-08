    

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

    CALL PrintNewLine

    RET