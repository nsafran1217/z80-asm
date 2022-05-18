
;View $100 bytes at $4400

ResetD:
    LD D,$00
    RET
;;Output $FF address in a table starting at address in HL. Destorys all registers
OutputHexData:
        CALL NewLine

        LD E,$FF                ;Load length of data to display into E -1 so the displayed address is correct
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte
        LD A,'-'
        CALL OutputChar
        PUSH HL                 ;Push HL to retrieve later. This contains the real address we need

        ADC HL,DE               ;16 bit add
              
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte

        LD E,$00                ;Load length of data to display into E
        POP HL                  ; restore HL to the real address
        CALL NewLine
        CALL ResetD
OutputHexLoop:
        LD A,(HL)
        CALL hexout             ;print A as hex char
        LD A,' '
        CALL OutputChar
        INC HL                  ;Inc ram address
        DEC E                   ;Dec address left to display
        INC D                   ;Inc number display per line
        LD A,D                  ;Check is we've printed 16 bytes
        CP $10  
        CALL Z, ResetD
        CALL Z, OutputAsciiValues       ;And print out ascii values   
            

        LD A,E                  ;ld count of bytes left to display
        CP $00                  ;check if zero
        JP NZ, OutputHexLoop    ;if not keep displaying

        LD IY,KeepPrintMessage  ;Ask if user wants to view more hex
        CALL PrintStr           ;Print
        CALL Input
        CP ' '                  ;is input space?
        JP Z,OutputHexData      ;Yes, print more hex,
        RET                     ;else, go back to caller
               
OutputAsciiValues:
        LD A,'|'
        CALL OutputChar
        LD A,' '
        CALL OutputChar         ; Print out seperator
        PUSH BC                 ; Preserve BC just in case
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
        CALL Z, NewLine 
        CALL Z, ResetD        
        RET Z
        JP OutputAsciiValuesLoop


