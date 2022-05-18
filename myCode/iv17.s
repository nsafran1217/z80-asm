;PORTSEL 0
;PORTSEL 0
;CONTSEL 1
;BASE ADDR $5X
;$50 - PORT A - DATA
;$51 - PORT B - DATA
;$52 - PORT A - CMD
;$53 - PORT B - CMD ;
;BLNK CLK STROBE DIN

PortACMD    = $52
PortAData   = $50
PortBCMD    = $53
PortBData   = $51

dinPin      = $01
strobePin   = $02
clkPin      = $04
blnkPin     = $08

    .org $4000

InitPortA:
    LD A, $0F               ;This sets the port to mode 0 (output)
    OUT (PortACMD), A

TestOut:

    LD A, $FF
    LD HL, $5000
    LD (HL), A
    INC HL
    LD (HL), A
    INC HL
    LD (HL), A
    INC HL
    LD (HL), A
    INC HL
    LD HL, $5000
    CALL Shift20Bits

    LD A, strobePin
    OUT (PortAData), A
    LD A, 0
    OUT (PortAData), A

    JP $0036





Shift20Bits:                ;Shift out 20 bits at memory location (HL), MSB order
    LD D, 20                ; number of bits to shift out

Shift20BitsLoop:
    LD A, (HL)              ;get first byte we are going to shift
    LD B,A
Shift8BitsLoop:
    DEC D
    PUSH AF                  ;Store what the byte is that we are working on
    AND %10000000           ;We only want the Most significant bit
    RR A
    RR A
    RR A
    RR A
    RR A
    RR A
    RR A                      ;Move it over to where Data in is (Bit 0)
    OUT (PortAData), A      ;Put out the data so its valid when the clock rises
    AND clkPin              ;And it with the clk pin bit
    OUT (PortAData), A      ;Out again with both clock and data
    LD A,0
    OUT (PortAData), A      ;And Out with 0

    LD A, D                 ;check if we have shifted out 20 bits
    CP 0
    JP Z, DoneShifting20    ;If we did, get out of this
    LD A,':'
    CALL OutputChar

    POP AF                   ;Get A back to what we started with
    RLCA                    ;Rotate it left
    CP B                    ;Check if it matches what was in HL
    JP NZ, Shift8BitsLoop   ;If not, keep shifting out
    INC HL                  ;Get next byte to shift out
    JP Shift20BitsLoop

DoneShifting20:
    POP AF
    RET


    .include monitor\uart.s

   .org $4ffe

    .word $0000