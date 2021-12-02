
;View $100 bytes at $4400
ViewHexData:
        ;LD IY,WhatAddrMessage   
        ;CALL PrintStr 
        ;LD D,$04                ;Get 4 charcters
        ;CALL AskForHex      ;Get address from user
        LD HL, $4400
        CALL OutputHexData      ;output $80 data starting at HL
        RET
ResetD:
    LD D,$00
    RET
;;Output $80 address in a table starting at address in HL. Destorys all registers
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
        CALL Z, NewLine         ;If we did do a new line and reset the counter
        CALL Z, ResetD
        LD A,E                  ;ld count of bytes left to display
        CP $00                  ;check if zero
        JP NZ, OutputHexLoop    ;if not keep displaying


        ;LD IY,KeepPrintMessage  ;Ask if user wants to view more hex
        ;CALL PrintStr           ;Print
        ;CALL Input
        ;LD E,$80                ;Reset D incase we want to print more
        ;CP ' '                  ;is input space?
        ;JP Z,OutputHexData      ;Yes, print more hex,
        RET                     ;else, go back to caller
               
