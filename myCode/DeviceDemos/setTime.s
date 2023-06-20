;Set time store in BCD at address $8000
;7 bytes long
;SS MM HH w DD mm yy 
;HH is special becuase this sets 24 or 12 hour and AM or PM
;See data sheet

InputChar   = $0035
OutputChar  = $0038
PrintStr    = $003B
Start       = $0040

    .org $4000

Prompt:
    CALL sdaOut
    LD IY, message
    CALL PrintStr
    CALL InputChar
    CP "Y"
    JP Z, SetTime
    JP Start

SetTime:
    LD HL, $8000        ;memory location of time paramaters
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
    .text "This will set the time to the value stored in $8000 in BCD format. SS MM HH w DD mm yy"
    .text "\r\n"
    .text "See manual of DS3231 for special paramaters to provide\r\nY to continue, any other to exit: "
    .data 0

    ;Padding
    .org $4ffe

    .word $0000