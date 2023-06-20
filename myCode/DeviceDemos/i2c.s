;General i2c subroutines
;sclPin and sdaPin are hard coded. Adjustements to code is needed to change.
;Many subroutines taken from here:
;https://github.com/Kris-Sekula/CA80/blob/master/RTC/RTC_0x2000_0x2300_v1.4.asm



sclPin      = 7 
sdaPin      = 6 
sdaMask = $40
sclAndsdaOutput = $00
sclOutAndsdaIn = $40
i2cAddress = $68

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

;Setup i2c device for a write and set address to $00
set_addr_W:					
	call start_i2c
	ld a,i2cAddress		; Write i2c address
    RLA                 ;Shift address left
    res 0,a             ;Make sure R/W bit is 0 for a write
	JP set_addr

;Setup i2c device for a read and set address to $00
set_addr_R:
	call start_i2c
	ld a,i2cAddress		
    RLA                 ;Shift address left
    set 0,a             ;Set R/W bit for read

;Finish the set_addr_r/w routine	
set_addr:
	call putbyte	;
	call get_ack	;

	CALL sdaOut
	
	ld a,00h	        ; Set address to $00
	call putbyte
	call get_ack	

	CALL sdaOut
	RET


get_ack:	; Get ACK from i2c slave
    CALL sdaIn
	call sclset			; raised CLK, now expect "low" on SDA as the sign on ACK	
	ld A,(PortAData)	; here read SDA and look for "LOW" = ACK, "HI" - NOACK or Timeout`
    ;CALL PrintRegs
    CALL sclclr         ;;IGNORE everything I wrote and bail
    ret                 ;;TO DO, Fix
    
    LD B, $FF
    BIT sdaPin,a
    JP Z, NACK

    ;LD A, "#"
    ;CALL OutputChar
	ret
	; ToDo - implement the ACK timeout, right now we blindly assume the ACK came in. (Implemented???)
NACK:
    
	ld A,(PortAData)	 	; here read SDA and look for "LOW" = ACK, "HI" - NOACK or Timeout`
    BIT sdaPin,a
    JP NZ, ACK
    djnz NACK
    ;LD A, "!"
    ;CALL OutputChar
    
ACK:
    call sclclr
    ret

; Send ACK to i2c bus
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
	

; Read 8 bits from i2c bus. Place into A
getbyte:	
        push bc
		CALL sdaIn 		;
		ld b,8
gb1:    call    sclset          ; Clock UP
		in A,(PortAData)		; SDA (RX data bit) is in Bit 6
		rlca					; move RX data bit to carry
        rlca
                
		rl      c              	; Shift CY into C
        call    sclclr          ; Clock DOWN
        djnz    gb1
        ld a,c             		; Return RX Byte in A
		pop bc
 
        ret

; Send byte from A to i2C bus
putbyte: 	
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

;Set sda pin on port A to IN
sdaIn:
    LD A, $cf               ;This sets the port to mode 3 (control)
    OUT (PortACMD), A
    LD A,sclOutAndsdaIn		;Set the bit mask for the pins
	OUT (PortACMD),A
    RET
;Set sda pin on port A to OUT
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
