PortACMD    = $52
PortAData   = $50
NumOfVFDTubes = 8
ScrollSpeed = $0006

;Known addresses

InputChar   = $0035
OutputChar  = $0038
PrintStr    = $003B
Start       = $0040
    
    
    
    .org $4000

    CALL InitPortA

    LD HL, TestMessage
    CALL ScrollOutString

    LD HL, LightShowTable

    LD B, 16
    
LightShowLoop:
    LD DE, $0005
    CALL WaitLoop
    PUSH AF
    PUSH HL
    CALL Shift20Bits
    POP HL
    POP AF
    INC HL
    INC HL
    INC HL
    DJNZ LightShowLoop



    ;JP Start





;;FAIL
    LD A, 1
    LD HL, CharBuffer
    INC HL
    INC HL
    LD (HL), A
    LD B, 20
LightShow:
    LD DE, $0005
    CALL WaitLoop
    LD HL, CharBuffer
    PUSH AF
    PUSH HL
    CALL Shift20Bits
    POP HL
    POP AF
    
    LD A, (HL)
    CP 0
    JP Z, nextByte
    RLCA
    JP C, SkipCarry1
    LD (HL),A
    JP LightShow

SkipCarry1:
    RRCA
    INC HL
    LD (HL), A
    JP LightShow

nextByte:
    INC HL
    LD A, (HL)
    CP 0
    JP Z, nextByte2
    RLCA
    JP C, SkipCarry2
    LD (HL),A
    JP LightShow

SkipCarry2:
    RRCA
    INC HL
    LD (HL), A
    JP LightShow


nextByte2:
    INC HL
    LD A, (HL)
    CP %00001000
    JP Z, Start
    RLCA
    LD (HL),A
    JP LightShow



    JP Start
    LD A,"!"
PrintAllChars:
    CALL ShiftOutChar
    CALL StrobeDisplay
    INC A
    CP 126
    JR C, PrintAllChars

Test:
    LD DE, $0040
    CALL WaitLoop
    LD HL, TestMessage
    CALL ShiftOutStringNULTerm
    LD DE, $0040
    CALL WaitLoop
    LD HL, TestMessage
    CALL ScrollOutString
    ;JP Start

    
TestOut:
    CALL InputChar
    CALL ShiftOutChar
    CALL StrobeDisplay
    JR TestOut


LightShowTable:
    .data $00,$00,$01
    .data $00,$00,$02
    .data $00,$00,$04
    .data $00,$00,$08
    .data $00,$00,$10
    .data $00,$00,$20
    .data $00,$00,$40
    .data $00,$00,$80
    .data $00,$01,$00
    .data $00,$02,$00
    .data $00,$04,$00
    .data $00,$08,$00
    .data $00,$10,$00
    .data $00,$20,$00
    .data $00,$40,$00
    .data $00,$80,$00

CharBuffer .blk 3
TestMessage: .asciiz "Test Long String"
    .include iv17.s
    .include iv17String.s
    .org $4A00
    .include iv17asciitable.s
    .org $4ffe

    .word $0000