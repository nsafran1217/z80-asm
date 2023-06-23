;Set time store in BCD at address $8000
;7 bytes long
;SS MM HH w DD mm yy 
;HH is special becuase this sets 24 or 12 hour and AM or PM
;See data sheet

PortACMD    = $52
PortAData   = $50

InputChar   = $0035
OutputChar  = $0038
PrintStr    = $003B
Start       = $0040

    .org $4000

Prompt:

    LD IY, message
    CALL PrintStr

    LD B, 7
    LD HL, InputBuffer
InputLoop:
    CALL InputChar
    CALL OutputChar
    CALL ATOHEX
    RLA
    RLA
    RLA
    RLA
    AND %11110000
    LD C, A
    CALL InputChar
    CALL OutputChar
    CALL ATOHEX
    AND %00001111
    OR C
    LD (HL), A
    INC HL
    DJNZ InputLoop

    ;CP "Y"
    ;JP Z, SetTime
    ;JP Start

SetTime:
    LD HL, InputBuffer       ;memory location of time paramaters
    CALL sdaOut

	;call WAIT_4
    ;CALL sdaOut
	call stop_i2c		; initiate bus
	call WAIT_4
	;CALL sdaOut
	call set_addr_W		; Set address counter to 00h
	CALL sdaOut


    LD B, 7
write_time_loop:
    LD A, (HL)       ;year
    CALL putbyte
    call get_ack
	CALL sdaOut
    INC HL
    djnz write_time_loop

    call stop_i2c

    JP Start


    .include i2c.s

 message:    
    .text "\r\n"
    .text "Enter time in BCD format. SSMMHHwwDDmmyy"
    .text "\r\n"
    .text "Seconds Minutes Hours Dayofweek Day Month Year"
    .text "\r\n"
    .text "See manual of DS3231 for special paramaters to provide in hours and months\r\n"
    .text "Will execute when 14 characters are entered: "
    .data 0
InputBuffer: .blk 15
ATOHEX:
		SUB $30
		CP 10
		RET M		; If result negative it was 0-9 so we're done
		SUB $7		; otherwise, subtract $7 more to get to $0A-$0F
		RET		


    ;Padding
    .org $4ffe

    .word $0000