
;Retrieves CP/M from disk and loads it in memory starting at E400h
;Uses calls to ROM subroutine for disk read.
;Reads track 0, sectors 2 to 26, then track 1, sectors 1 to 25
;This program is loaded into LBA sector 0 of disk, read to loc. 0800h by ROM disk_read subroutine, and executed.
;
hstbuf:	.equ	4100h	;will put 256-byte raw sector here
disk_read:	.equ	30h	;subroutine in 2K ROM
cpm:	.equ	0FA00h	;CP/M cold start entry in BIOS
    .org	4000h	;Start of RAM, configuration 0
    ;Read track 0, sectors 2 to 26
    ld	a,2	;starting sector -- sector 1 reserved
    ld	(sector),a
    ld	hl,0E400h	;memory address -- start of CCP
    ld	(dmaad),hl
    ld	a,0	;CP/M track
    ld	(track),a
rd_trk_0_loop: 	
    call 	read
    ld	a,(sector)
    cp	26
    jp	z,rd_trk_1
    inc	a
    ld	(sector),a
    ld	hl,(dmaad)
    ld	de,128
    add	hl,de
    ld	(dmaad),hl
    jp	rd_trk_0_loop
    ;Read track 1, sectors 1 to 25
rd_trk_1:	
    ld	a,1
    ld	(track),a
    ld	hl,(dmaad)
    ld	de,128
    add 	hl,de
    ld	(dmaad),hl
    ld	a,1	;starting sector
    ld	(sector),a
rd_trk_1_loop: 	
    call	read
    ld	a,(sector)
    cp	25
    jp	z,done
    inc	a
    ld	(sector),a
    ld	hl,(dmaad)
    ld	de,128
    add	hl,de
    ld	(dmaad),hl
    jp	rd_trk_1_loop
done:	
    LD C,$70                ;Load disable rom address
    LD B,$01                ;Load disable rom bit
    OUT (C),B               ;send bit
    jp	cpm	;to BIOS cold start entry
read:
;Read one CP/M sector from disk 0
;Track number in 'track'
;Sector number in 'sector'
;Dma address (location in memory to place the CP/M sector) in 'dmaad' (0-65535)
;                        
    ld	hl,hstbuf	;buffer to place raw disk sector (256 bytes)
    ld	a,(sector)
    ld	c,a	;LBA bits 0 to 7
    ld	a,(track)
    ld	b,a	;LBA bits 8 to 15
    ld	e,00h	;LBA bits 16 to 23
    call  	disk_read          	;subroutine in ROM
    ;Transfer top 128-bytes out of buffer to memory
    ld	hl,(dmaad)	;memory location to place data read from disk
    ld	de,hstbuf	;host buffer
    ld	b,128	;size of CP/M sector
rd_sector_loop: 	
    ld	a,(de)	;get byte from host buffer
    ld	(hl),a	;put in memory
    inc	hl
    inc	de
    djnz 	rd_sector_loop 	;put 128 bytes into memory
    in	a,(0fh)	;get status
    and	01h	;error bit
    ret
sector:	db	00h
track:	db	00h
dmaad:	dw	0000h
    .org $40fe
    NOP
