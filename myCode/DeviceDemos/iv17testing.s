PortACMD    = $52
PortAData   = $50
NumOfVFDTubes = 8

;Known addresses

InputChar   = $0035
OutputChar  = $0038
PrintStr    = $003B
Start       = $0040
    
    
    
    .org $4000

    CALL InitPortA

    LD HL, TestMessage
    CALL ScrollOutString





    LD A,"!"
PrintAllChars:
    CALL ShiftOutChar
    CALL StrobeDisplay
    INC A
    CP 126
    JR C, PrintAllChars

Test:

    CALL WAIT_4
    LD HL, TestMessage
    CALL ShiftOutStringNULTerm
    CALL WAIT_4
    LD HL, TestMessage
    CALL ScrollOutString
    ;JP Start

    
TestOut:
    CALL InputChar
    CALL ShiftOutChar
    CALL StrobeDisplay
    JR TestOut

TestMessage: .asciiz "Test Long String"
    .include iv17.s
    .include iv17String.s
    .org $4A00
    .include iv17asciitable.s
    .org $4ffe

    .word $0000