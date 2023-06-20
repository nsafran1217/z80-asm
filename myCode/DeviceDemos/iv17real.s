

;Known addresses
InputChar   = $0035
OutputChar  = $0038
Start       = $0040

    .org $4000

    CALL InitPortA


    LD A,"!"
PrintAllChars:
    CALL ShiftOutChar
    INC A
    CP 81
    JR C, PrintAllChars



TestOut:
    CALL InputChar
    CALL ShiftOutChar
    JR TestOut


    .include iv17.s
    .org $4A00
    .include iv17ascii.s
    .org $4ffe

    .word $0000