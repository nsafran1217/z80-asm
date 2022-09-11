


ResetD:
    LD D,$00
    RET
;;Output BC addresses in a table starting at address in HL. Assume Destorys all registers
OutputHexDumpTable:
        CALL PrintNewLine
        PUSH BC
        DEC BC                  ;So value is displayed correctly 
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte
        LD A,"-"
        CALL OutputChar
        PUSH HL                 ;Push HL to retrieve later. This contains the real address we need
        ADD HL,BC               ;16 bit add
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte
        CALL PrintNewLine
        
        LD B, $10               ;Print out 16 offset lables
        LD A, $00 
        LD IY, OffsetMSG
        CALL PrintStr              
OffsetLabelLoop:
        CALL hexout
        CALL PrintSpace
        INC A
        DJNZ OffsetLabelLoop
        CALL PrintNewLine
        CALL PrintDashLine


        POP HL                  ; restore HL to the real address
        POP BC                  ;Restore correct value
        CALL PrintNewLine
        CALL ResetD
OutputHexLoop:
        LD A, D
        CP $00
        CALL Z, OutputHexTableRowName     ;Print the address on the left first
        LD A,(HL)
        CALL hexout             ;print A as hex char
        LD A,' '
        CALL OutputChar
        INC HL                  ;Inc ram address
        DEC BC                   ;Dec address left to display           ;;;;;
       ; CALL PrintRegs
        INC D                   ;Inc number display per line
        LD A,D                  ;Check if we've printed 16 bytes
        CP $10  
        CALL Z, ResetD
        CALL Z, OutputAsciiValues       ;And print out ascii values   

        LD A,B                  ;ld count of bytes left to display
        CP $00                  ;check if zero
        JP Z, OutputHexLoopReallyDone
        JP OutputHexLoop        
OutputHexLoopReallyDone:        ;Check second byte if its zero
        LD A, C
        CP $00
        JP NZ, OutputHexLoop    ;if not keep displaying
        RET                     ;else, go back to caller

OutputHexTableRowName:              
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte
        LD A, ":"
        CALL OutputChar
        LD A, " "
        CALL OutputChar
        RET

OutputAsciiValues:
        LD A,'|'
        CALL OutputChar
        LD A,' '
        CALL OutputChar         ; Print out seperator
        PUSH BC
        LD B, $00               ;Subrtact 16 from HL
        LD C, $10
        SBC HL,BC
        POP BC
OutputAsciiValuesLoop:
        LD A,(HL)
        CP $20                  ;Check if value is less than $20
        JP C, InvalidAscii       ;If it is, Its definetly bad
        CP $7F                  ;check if value is greater tahn $7f
        JP C, ValidAscii       ;if it isnt, then we have valid ascii 
InvalidAscii:
        LD A,'.'                ;When we dont, just print a .

ValidAscii:                     ;when we have a good ascii character, or a .
        CALL OutputChar
        INC HL                  ;Inc ram address
        INC D                   ;Inc number display per line
        LD A,D                  ;Check if we've printed 16 bytes
        CP $10 
        CALL Z, PrintNewLine
        CALL Z, ResetD        
        RET Z
        JP OutputAsciiValuesLoop


