;Set time store in BCD at address $8000
;7 bytes long
;SS MM HH w DD mm yy 
;HH is special becuase this sets 24 or 12 hour and AM or PM
;See data sheet

InputChar   = $0035
OutputChar  = $0038
PrintString = $003B
Start       = $0040


TestSetTime:
    LD HL, $8000        ;memory location of time paramaters
    CALL sdaOut

	;call WAIT_4
    ;CALL sdaOut
	call stop_i2c		; initiate bus
	call WAIT_4
	;CALL sdaOut
	call set_addr_W		; Set address counter to 00h
	CALL sdaOut



write_time_loop:
    LD B, 7
    LD A, (HL)       ;year
    CALL putbyte
    call get_ack
	CALL sdaOut
    INC HL
    djnz write_time_loop



    call stop_i2c

    .include i2c.s

message: .asciiz "This will set the time to the value stored in $8000 in BCD format. SS MM HH w DD mm yy \n\r
See manual of DS3231 for special paramaters to provide\n\r
Y to continue, any other to exit:"