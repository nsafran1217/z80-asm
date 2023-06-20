;Read time out to address $8100
;7 bytes long
;SS MM HH w DD mm yy 
;HH is special becuase this sets 24 or 12 hour and AM or PM
;See data sheet

InputChar   = $0035
OutputChar  = $0038
PrintStr    = $003B
Start       = $0040
RTCAddress  = $68

    .org $4000

Setup:
    CALL sdaOut         ;Note that this sets all pins to out
                        ;This sets us up for the IV17 as well

ReadTime:
    LD HL, TimeBuffer   ;memory location to dump to

	call stop_i2c		; initiate bus
	call WAIT_4
	
	call set_addr_W		; Set address counter to 00h

    call start_i2c      ;Repeated start
    ld a,RTCAddress		; Start the read command without sending an address
    RLA
    set 0,a             ;Set R/w bit to Read
	call putbyte
	call get_ack

    LD B, 7
read_time_loop:
    CALL getbyte
	LD (HL),A
	INC HL
	CALL send_ack
    djnz read_time_loop

    call stop_i2c
    JP Start









    .include i2c.s
    
TimeBuffer: .blk 7
    ;Padding
    .org $4ffe

    .word $0000