    .org $0000
        LD SP,$ff00 
START:
             
        LD D,$04                ;Get 4 charcters
        LD HL,$0000
AskForAddressLoop:   
        ;CALL Input
        ;CALL OutputChar
        LD B,$31
        LD A,B
        CALL ATOHEX
        PUSH AF
        DEC D                   ;Dec char counter
        LD A,D                  ;Move D to A
        CP $00                  ;Is 0?
        JP NZ,AskForAddressLoop ;Keep going if we need more CHARS

        POP AF
        LD B,A
        POP AF
        RLC A
        RLC A
        RLC A
        RLC A
        OR B

        LD HL,$7000
        LD (HL),A
        INC HL

        POP AF
        LD B,A
        POP AF
        RLC A
        RLC A
        RLC A
        RLC A
        OR B

        LD (HL),A
        LD HL,($7000)
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        JP START
ATOHEX:
		SUB $30
		CP 10
		RET M		; If result negative it was 0-9 so we're done
		SUB $7		; otherwise, subtract $7 more to get to $0A-$0F
		RET		
