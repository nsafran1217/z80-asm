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

sclPin      = 6 ;pin 7
sdaPin      = 7 ;pin 8
sclAndsdaOutput = $00
sclOutAndsdaIn = $80

;Known addresses
InputChar   = $0035
OutputChar  = $003A
Start       = $0040


   .org $4000

InitPortA:
    LD A, $3F               ;This sets the port to mode 3 (control)
    OUT (PortACMD), A
    LD A, sclAndsdaOutput   ;Set all to output
    OUT (PortACMD), A


; Procedure to copy time from Hardware RTC to software RTC in CA80 (seconds are maintained in RAM starting from address 0xFFEDh - sec, 0xFFEEh - min, 0xFFEFh etc.)
;
; When finished, the procedure will jump straight to the CA80 Display Time program *E[0]

GET_RTC:



	CALL sdaOut

GETTIME: ; Synch CA80 time with RTC

	ld hl,$8000

	call stop_i2c		; initiate bus
	call WAIT_4
	
	call set_addr		; Set address counter to 00h
	call start_i2c
	ld a,$D1			; Read current address A1 for EEPROM D0 for RTC
	call putbyte		
	call get_ack		; now get first data byte back from slave, SDA-in
	call getbyte		; get seconds data should be in A
	ld (hl),a
	inc hl
	call send_ack ;
	call getbyte		; get minutes
    ld (hl),a
    inc hl
    call send_ack
	call getbyte		; get hours
	ld (hl),a
	inc hl
	call send_ack
	call getbyte		; get date
	ld (hl),a
	inc hl
	call send_ack
	call getbyte		; get month
	ld (hl),a
	inc hl
	call send_ack
    call getbyte            ; get year
    ld (hl),a
    inc hl

	call send_noack
	call stop_i2c
	
	RST 10h			; clear display procedure
	defb 80h		; all digits
	


;
;
; 
;	

	
SAVETIME:	; save current software RTC to HW RTC procedure, call by: *E[G][2100]=

    CALL sdaOut

	ld hl,0ffedh		; RTC SEC position in CA80
	
	call stop_i2c			; initiate bus

	call set_addr
	ld a,(hl)			; save seconds to EEPROM under address 00
	call putbyte
	call get_ack
	
	CALL sdaOut
	
	inc hl
	ld a,(hl)		; save minutes to EEPROM under address 01
	call putbyte
	call get_ack
	
	CALL sdaOut
	
	inc hl
	ld a,(hl)		; save hours to EEPROM under address 02
	call putbyte
	call get_ack
	CALL sdaOut

	inc hl
	ld a,(hl)		; save day to EEPROM
	call putbyte
	call get_ack
	
	CALL sdaOut

	inc hl
	ld a,(hl)		; save month to EEPROM
	call putbyte
	call get_ack
	
	CALL sdaOut
	
	inc hl
	ld a,(hl)
	call putbyte
	call get_ack
	
	CALL sdaOut
	
	call stop_i2c
	rst 30h
	
;
;
;
;
;


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

set_addr:
					; Reset device address counter to 00h, for i2c device on address D0
	call start_i2c
	ld a,$68		; Write Command A0 for EEPROM D0 for RTC
	call putbyte	;
	call get_ack	;
	
	CALL sdaOut
	
	ld a,00h	; read from address 00h
	call putbyte
	call get_ack	

	CALL sdaOut
	
	ret

get_ack:	; Get ACK from i2c slave
    Call sdaIn
	call sclset			; raised CLK, now expect "low" on SDA as the sign on ACK	
	ld A,(PortAData)	 	; here read SDA and look for "LOW" = ACK, "HI" - NOACK or Timeout`
	call sclclr
	ret
	; ToDo - implement the ACK timeout, right now we blindly assume the ACK came in.

send_ack: 
    CALL sdaOut	;
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
		in A,(PortAData)			; SDA (RX data bit) is in A.0
		rrca					; move RX data bit to CY
		rl      c              	; Shift CY into C
        call    sclclr          ; Clock DOWN
        djnz    gb1
        ld a,c             		; Return RX Byte in A
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
        jr      nc,sdz              ; jump if sda was 0
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
    LD A,sclOutAndsdaIn
	OUT (PortACMD),A
    RET
sdaOut:
    LD A,sclAndsdaOutput 		
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

    .org $4ffe

    .word $0000