;PUTSYS
;Copies the memory image of CP/M loaded at E400h onto tracks 0 and 1 of the first CP/M disk
;Load and run from ROM monitor
;Uses calls to BIOS, in memory at FA00h
;Writes track 0, sectors 2 to 26, then track 1, sectors 1 to 25
seldsk:	.equ	0fa1bh 	;pass disk no. in c
setdma:	.equ	0fa24h	;pass address in bc
settrk:	.equ	0fa1eh	;pass track in reg C
setsec:	.equ	0fa21h	;pass sector in reg c
write:	.equ	0fa2ah	;write one CP/M sector to disk
monitor_warm_start: 	.equ	0000h	;Return to ROM monitor
        .org	5000h	;First byte in RAM when memory in configuration 0
        ld	c,00h	;CP/M disk a
        call	seldsk
        ;Write track 0, sectors 2 to 26
        ld	a,2	;starting sector
        ld	(sector),a
        ld	hl,0E400h	;start of CCP
        ld	(address),hl
        ld	c,0	;CP/M track
        call 	settrk
wr_trk_0_loop: 	ld	a,(sector)
        ld	c,a	;CP/M sector
        call	setsec
        ld	bc,(address)	;memory location
        call	setdma
        call	write
        ld	a,(sector)
        cp	26	;done:
        jp	z,wr_trk_1	;yes, start writing track 1
        inc	a	;no, next sector
        ld	(sector),a
        ld	hl,(address)
        ld	de,128
        add	hl,de
        ld	(address),hl
        jp	wr_trk_0_loop
;Write track 1, sectors 1 to 25
wr_trk_1:	ld	c,1
        call 	settrk
        ld	hl,(address)
        ld	de,128
        add	hl,de
        ld	(address),hl
        ld	a,1
        ld	(sector),a
wr_trk_1_loop: 	ld	a,(sector)
        ld	c,a	;CP/M sector
        call	setsec
        ld	bc,(address)	;memory location
        call	setdma
        call	write
        ld	a,(sector)
        cp	25
        jp	z,done
        inc	a
        ld	(sector),a
        ld	hl,(address)
        ld	de,128
        add	hl,de
        ld	(address),hl
        jp	wr_trk_1_loop
done:	jp	monitor_warm_start
sector:	db	00h
address:	dw	0000h
    .org $50fe  ;pad to FF bytes
    NOP