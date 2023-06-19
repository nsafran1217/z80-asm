;PORTSEL 0
;PORTSEL 0
;CONTSEL 1
;BASE ADDR $5X
;$50 - PORT A - DATA
;$51 - PORT B - DATA
;$52 - PORT A - CMD
;$53 - PORT B - CMD ;


PortACMD    = $52
PortAData   = $50
PortBCMD    = $53
PortBData   = $51

sclPin      = 7 
sdaPin      = 6 
sdaMask = $40
sclAndsdaOutput = $00
sclOutAndsdaIn = $40
RTCAddress = $68

;Known addresses
InputChar   = $0035
OutputChar  = $003A
Start       = $0040


   .org $4000

InitPortA:
    LD A, $cf               ;This sets the port to mode 3 (control)
    OUT (PortACMD), A
    LD A, sclAndsdaOutput   ;Set all to output
    OUT (PortACMD), A
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



WAIT_4:	; delay
		push	AF
		push	BC
		push	DE
		ld	de,0400h
W40:	djnz W40
		dec de
		ld a,d
		or a
		jp	nz,W40
		pop	DE
		pop	BC
		pop	AF
		ret

set_addr_W:
					; Reset device address counter to 00h, for i2c device on address D0
	call start_i2c
	ld a,RTCAddress		; Write Command A0 for EEPROM D0 for RTC
    RLA
    res 0,a
	JP set_addr
set_addr_R:
					; Reset device address counter to 00h, for i2c device on address D0
	call start_i2c
	ld a,RTCAddress		; Write Command A0 for EEPROM D0 for RTC
    RLA
    set 0,a
	
set_addr:
	
	call putbyte	;
	call get_ack	;

	CALL sdaOut
	
	ld a,00h	; read from address 00h
	call putbyte
	call get_ack	

	CALL sdaOut
	RET

get_ack:	; Get ACK from i2c slave
    CALL sdaIn
	call sclset			; raised CLK, now expect "low" on SDA as the sign on ACK	
	ld A,(PortAData)	 	; here read SDA and look for "LOW" = ACK, "HI" - NOACK or Timeout`
    ;CALL PrintRegs
    CALL sclclr         ;;IGNORE everything I wrote and bail
    ret                 ;;
    
    LD B, $FF
    BIT sdaPin,a
    JP Z, NACK

    LD A, "#"
    CALL OutputChar
	ret
	; ToDo - implement the ACK timeout, right now we blindly assume the ACK came in. (Implemented???)
NACK:
    
	ld A,(PortAData)	 	; here read SDA and look for "LOW" = ACK, "HI" - NOACK or Timeout`
    BIT sdaPin,a
    JP NZ, ACK
    djnz NACK
    LD A, "!"
    CALL OutputChar
    
ACK:
    call sclclr
    ret


send_ack: 
    CALL sdaOut	;
    LD A,0
    RRCA
    CALL sdaput
	call sclset		; Clock SCL
	call sclclr

	ret

send_noack:		; Send NAK (no ACK) to i2c bus (master keeps SDA HI on the 9th bit of data)
	CALL sdaOut	
	call sdaset			; 	
	call sclset			; Clock SCL 
	call sclclr
	ret
	


getbyte:	; Read 8 bits from i2c bus
        push bc
		CALL sdaIn 		;
		ld b,8
gb1:    call    sclset          ; Clock UP
		in A,(PortAData)			; SDA (RX data bit) is in Bit 6
		rlca					; move RX data bit to CY
        rlca
                
		rl      c              	; Shift CY into C
        call    sclclr          ; Clock DOWN
        djnz    gb1
        ld a,c             		; Return RX Byte in A
        ;CALL PrintRegs
		pop bc
 
        ret


putbyte: 	; Send byte from A to i2C bus
        push    bc
        ld      c,a             ;Shift register
        ld      b,8
pbks1:  sla     c               ;B[7] => CY
        call    sdaput          ; & so to SDA
        call    sclclk          ;Clock it
        djnz    pbks1
        call    sdaset          ;Leave SDA high, for ACK
        pop     bc
        ret


sclclk:         ;	"Clock" the SCL line Hi -> Lo
			call    sclset
			call    sclclr
			ret


sdaput:        ; CY state copied to SDA line, without changing SCL state
        in      a,(PortAData)       ;read in Port
		res     sdaPin,a            ;Reset sda
        JP      nc,sdz              ; jump if sda was 0
        set     sdaPin,a            ; else set it again????? are these comments right??
sdz:    out     (PortAData),a
        ret

stop_i2c:        ; i2c STOP sequence, SDA goes HI while SCL is HI
        push    af
        call    sdaclr
        call    sclset
        call    sdaset
        pop     af
        ret

start_i2c:          ; i2c START sequence, SDA goes LO while SCL is HI
			call	sdaset
			call    sclset
			call    sdaclr
			call    sclclr
			call    sdaset
			ret


sdaIn:
    LD A, $cf               ;This sets the port to mode 3 (control)
    OUT (PortACMD), A
    LD A,sclOutAndsdaIn		;Set the bit mask for the pins
	OUT (PortACMD),A
    RET
sdaOut:
    LD A, $cf               ;This sets the port to mode 3 (control)
    OUT (PortACMD), A
    LD A,sclAndsdaOutput 	;Set the bit mask for the pins	
	OUT (PortACMD),A
    RET

sclset: ; SCL HI without changing SDA     	
        in      a,(PortAData)
        set     sclPin,a
        out     (PortAData),a
        ret

sclclr:  ; SCL LO without changing SDA       	
        in      a,(PortAData)
        res     sclPin,a
        out     (PortAData),a
        ret

sdaset:	; SDA HI without changing SCL
        in      a,(PortAData)
        set     sdaPin,a
        out     (PortAData),a
        ret

sdaclr: ; SDA LO without changing SCL   	
        in      a,(PortAData)
        res     sdaPin,a
        out     (PortAData),a
        ret


    .include ..\monitorv3\printregs.s
    .include ..\monitorv3\hexout.s
    .include ..\monitorv3\String.s

    .org $4ffe

    .word $0000