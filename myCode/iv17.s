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
gridBit     = $40

    .org $4000

InitPortA:
    LD A, $0F               ;This sets the port to mode 0 (output)
    OUT (PortACMD), A

TestOut:

    
    LD HL, $5000
    LD A, $44
    LD (HL), A
    INC HL
    LD A, $aa
    LD (HL), A
    INC HL
    LD A, $aa
    LD (HL), A


    LD HL, $5000
    CALL Shift20Bits
    LD A,'+'
    CALL OutputChar

    LD A, strobePin
    OUT (PortAData), A
    LD A, 0
    OUT (PortAData), A

    LD A,'*'
    CALL OutputChar
    
    
    JP $0036





Shift20Bits:                ;Shift out 20 bits at memory location (HL), MSB order
    LD D, 20                ; number of bits to shift out
    LD E, 8

Shift20BitsLoop:
    LD B, (HL)              ;get first byte we are going to shift
    ;LD B,A
Shift8BitsLoop:
    DEC D
    DEC E
    LD A, B
    PUSH AF                  ;Store what the byte is that we are working on
    AND %10000000           ;We only want the Most significant bit
    RR A
    RR A
    RR A
    RR A
    RR A
    RR A
    RR A                    ;Move it over to where Data in is (Bit 0)
    ;OR 1                    ;TESTING
    OUT (PortAData), A      ;Put out the data so its valid when the clock rises
    OR clkPin               ;And it with the clk pin bit
    OUT (PortAData), A      ;Out again with both clock and data
    LD A,0
    OUT (PortAData), A      ;And Out with 0

    LD A, D                 ;check if we have shifted out 20 bits
    CP 0
    JP Z, DoneShifting20    ;If we did, get out of this
    LD A,'!'
    CALL OutputChar
    
    POP AF
    RLCA
    LD B,A
    LD A,E                  ;get counter of bits
    CP 0                    ;if its not empty keep loooping
    JP NZ, Shift8BitsLoop   ;If not, keep shifting out
    INC HL                  ;Get next byte to shift out
    LD E, 8
    JP Shift20BitsLoop

DoneShifting20:
    POP AF
    RET


    .include monitor\uart.s

   .org $4ffe

    .word $0000