;PORTSEL 0
;PORTSEL 0
;CONTSEL 1
;BASE ADDR $5X
;$50 - PORT A - DATA
;$51 - PORT B - DATA
;$52 - PORT A - CMD
;$53 - PORT B - CMD ;



RTCAddress = $68

;Known addresses
InputChar   = $0035
OutputChar  = $0038
Start       = $0040


   .org $4000

InitPortA:
    CALL sdaOut
    ;call WAIT_4
    ;call WAIT_4
    ;call WAIT_4
    ;call WAIT_4
    ;call WAIT_4
    ;call WAIT_4
    ;    call WAIT_4
    ;call WAIT_4
    ;call WAIT_4

    JP TestReadTime
    

TestSetTime:

	;call WAIT_4
    ;CALL sdaOut
	call stop_i2c		; initiate bus
	call WAIT_4
	;CALL sdaOut
	call set_addr_W		; Set address counter to 00h
	CALL sdaOut

    LD A, $20        ;seconds
    CALL putbyte
    call get_ack
	CALL sdaOut

    LD A, $33        ;minutes
    CALL putbyte
    call get_ack
	CALL sdaOut

    LD A, $8        ;hours
    CALL putbyte
    call get_ack
	CALL sdaOut

    LD A, $1         ;Day of week
    CALL putbyte
    call get_ack
	CALL sdaOut

    LD A, $17        ;date
    CALL putbyte
    call get_ack
	CALL sdaOut

    LD A, $12        ;month
    CALL putbyte
    call get_ack
	CALL sdaOut

    LD A, $22       ;year
    CALL putbyte
    call get_ack
	CALL sdaOut

    call stop_i2c


TestReadTime:

	

	call stop_i2c		; initiate bus
	call WAIT_4
	
	call set_addr_W		; Set address counter to 00h

    call start_i2c
    ld a,RTCAddress		; Write Command A0 for EEPROM D0 for RTC
    RLA
    set 0,a
	call putbyte	;
	call get_ack	;

    ld hl,$8000
    ;Need to request 7 bytes
    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack

    
	call send_noack
	call stop_i2c

    JP Start


	.include i2c.s

    .include ..\monitorv3\printregs.s
    .include ..\monitorv3\hexout.s
    .include ..\monitorv3\String.s

    .org $4ffe

    .word $0000