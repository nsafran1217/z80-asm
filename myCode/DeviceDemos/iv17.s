;PORTSEL 0
;PORTSEL 0
;CONTSEL 1
;BASE ADDR $5X
;$50 - PORT A - DATA
;$51 - PORT B - DATA
;$52 - PORT A - CMD
;$53 - PORT B - CMD ;
;BLNK CLK STROBE DIN




dinPin      = $01
strobePin   = $02
clkPin      = $04
blnkPin     = $08
gridBit     = $04


InitPortA:
    LD A, $CF               ;This sets the port to mode 3 (control)
    OUT (PortACMD), A
    LD A, $00               ;All pins are output
    OUT (PortACMD), A
    RET


;Shift out character in A
;Destroys HL
ShiftOutChar:
    PUSH AF
    PUSH AF
    LD HL, AsciiIndexIV17   ;Put index table in HL
    ADD L                   ;Add character to index
    LD L,A                  ;Put new low byte into HL
    LD A,(HL)               ;Get low byte address for 3byte code to shift out
    LD H, >AsciiTableIV17   ;Put High byte of table in H
    LD L, a                 ;Put indexed byte into low byte

    POP AF
    CP "u"                  ;Check if characteris higher than "u"
    JP NC, HighAsciiChar    ;Jump if greater than "u"
    JP ShiftOutTheData
HighAsciiChar:
    INC H                   ;Inc to get to next half of ASCII table
ShiftOutTheData:
    CALL Shift20Bits        ;Shift out the value in HL
    POP AF
    RET

Strobe:                     ;Strobe so data is latched
    PUSH AF
    LD A, strobePin
    OUT (PortAData), A
    LD A, 0
    OUT (PortAData), A
    POP AF
    RET

;Shift out 20 bits at memory location (HL), MSB order
;Destroys HL and AF
Shift20Bits:                
    PUSH DE
    PUSH BC
    LD D, 20                ; number of bits to shift out

    LD E, 4                 ;For first btye, we only want to do the low nybble
    LD A, (HL)              ;get first byte we are going to shift
    OR gridBit
    RLA                        ;Shift it over so the low nybble will be output
    RLA
    RLA
    RLA
    LD B,A
Shift20BitsLoop:
    
    ;LD B,A
Shift8BitsLoop:
    DEC D
    DEC E
    LD A, B
    PUSH AF                  ;Store what the byte is that we are working on
    AND %10000000            ;We only want the Most significant bit
    RLCA                     ;Move it over to where Data in is (Bit 0)   
    OUT (PortAData), A      ;Put out the data so its valid when the clock rises
    OR clkPin               ;or it with the clk pin bit
    OUT (PortAData), A      ;Out again with both clock and data
    LD A,0
    OUT (PortAData), A      ;And Out with 0

    LD A, D                 ;check if we have shifted out 20 bits
    CP 0
    JP Z, DoneShifting20    ;If we did, get out of this
    
    POP AF
    RLCA
    LD B,A
    LD A,E                  ;get counter of bits
    CP 0                    ;if its not empty keep loooping
    JP NZ, Shift8BitsLoop   ;If not, keep shifting out
    INC HL                  ;Get next byte to shift out
    LD E, 8
    LD B, (HL)              ;get first byte we are going to shift
    JP Shift20BitsLoop

DoneShifting20:
    POP AF
    POP BC
    POP DE
    RET
