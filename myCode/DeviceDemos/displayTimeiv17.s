;Read time out to address $8100
;7 bytes long
;SS MM HH w DD mm yy 
;HH is special becuase this sets 24 or 12 hour and AM or PM
;See data sheet
PortACMD    = $52
PortAData   = $50

InputChar   = $0035
OutputChar  = $0038
;PrintStr    = $003B
Start       = $0040
RTCAddress  = $68

    .org $4000

Setup:
    CALL sdaOut         ;Note that this sets all pins to out
                        ;This sets us up for the IV17 as well

ReadTime:
    LD HL, TimeBufferVar   ;memory location to dump to

	call stop_i2c		; initiate bus
	
	call set_addr_W		; Set address to $00, ready for write

    call start_i2c      ;Repeated start
    ld a,RTCAddress		; Start the read command without sending an address
    RLA
    set 0,a             ;Set R/w bit to Read
	call putbyte
	call get_ack


    CALL getbyte    ;sec
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte    ;min
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte    ;hour
    AND %00011111   ;Strip garbage off
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte    ;Day of Week
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte    ;Day
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte    ;Month
    AND %00011111   ;Strip garbage off
	LD (HL),A
	INC HL
	CALL send_ack

    CALL getbyte    ;Year
	LD (HL),A
	INC HL

	
    call send_noack ;SEND NOACK WHEN DONE READING
    call stop_i2c

    ;JP Start


DisplayTime:
    LD HL, TimeBufferVar
    LD B, 3         ;Only do time
    LD E, (HL)
    ;LD A, 0
    ;CALL ShiftOutChar
    ;CALL ShiftOutChar
DisplayTimeLoop: 
    LD A, (TimeBufferVar)         ;Load value from memory
    RRCA             ;Check if even
    JP C, NoColon
    LD A, ":"   
    JP SkipNoColon:
NoColon:
    LD A, 0
SkipNoColon:
    CALL ShiftOutChar
    LD A, (HL)
    AND %00001111       ;get low nybble
    ADD "0"             ;Convert to ascii
    CALL ShiftOutChar   
    LD A, (HL)          ;Get A back
    AND %11110000       ;Get high nybble
    RRCA
    RRCA
    RRCA
    RRCA                ;Move nybble over
    ADD "0"
    CALL ShiftOutChar
    INC HL              ;Next
    djnz DisplayTimeLoop
    CALL StrobeDisplay

    JP ReadTime
    JP Start




    .include i2c.s
    .include iv17.s

TimeBufferVar: blk 8    ;Variable for time to be read into

    .org $4A00
    .include iv17asciitable.s

    ;Padding
    .org $4ffe
    .word $0000
