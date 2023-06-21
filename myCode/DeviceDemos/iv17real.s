PortACMD    = $52
PortAData   = $50

;Known addresses
InputChar   = $0035
OutputChar  = $0038
Start       = $0040

    .org $4000

    CALL InitPortA


    LD A,"!"
PrintAllChars:
    CALL ShiftOutChar
    CALL StrobeDisplay
    INC A
    CP 81
    JR C, PrintAllChars



TestOut:
    CALL InputChar
    CALL ShiftOutChar
    CALL StrobeDisplay
    JR TestOut


    .include iv17.s
    .org $4A00
    .include iv17asciitable.s
    .org $4ffe

    .word $0000