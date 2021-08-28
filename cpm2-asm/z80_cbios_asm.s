;Edit for my custom machine nsafran1217@gmail.com
;I used the variabled in the IO seciont
UART = $00
UARTLSR = $05

IDESTATUS = $47
IDESECTORCOUNT = $42
IDELBABITS0TO7 = $43
IDELBABITS8TO15 = $44
IDELBABITS15TO23 = $45
IDEDRIVEHEADREG = $46
IDEDATAREG = $40   

;	skeletal cbios for first level of CP/M 2.0 alteration
;
ccp:	.equ	0E400h		;base of ccp
bdos:	.equ	0EC06h		;bdos entry
bios:	.equ	0FA00h		;base of bios
cdisk:	.equ	0004h		;address of current disk number 0=a,... l5=p
iobyte:	.equ	0003h		;intel i/o byte
disks:	.equ	04h		;number of disks in the system
;
	org	bios		;origin of this program
nsects:	.equ	($-ccp)/128	;warm start sector count
;
;	jump vector for individual subroutines
;
	JP	boot	;cold start
wboote:	JP	wboot	;warm start
	JP	const	;console status
	JP	conin	;console character in
	JP	conout	;console character out
	JP	list	;list character out
	JP	punch	;punch character out
	JP	reader	;reader character out
	JP	home	;move head to home position
	JP	seldsk	;select disk
	JP	settrk	;set track number
	JP	setsec	;set sector number
	JP	setdma	;set dma address
	JP	read	;read disk
	JP	write	;write disk
	JP	listst	;return list status
	JP	sectran	;sector translate
;
;	fixed data tables for four-drive standard
;	ibm-compatible 8" disks
;	no translations
;
;	disk Parameter header for disk 00
dpbase:	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, dpblk
	defw	chk00, all00
;	disk parameter header for disk 01
	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, dpblk
	defw	chk01, all01
;	disk parameter header for disk 02
	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, dpblk
	defw	chk02, all02
;	disk parameter header for disk 03
	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, dpblk
	defw	chk03, all03
;
;	sector translate vector
trans:	defb	 1,  7, 13, 19	;sectors  1,  2,  3,  4
	defb	25,  5, 11, 17	;sectors  5,  6,  7,  6
	defb	23,  3,  9, 15	;sectors  9, 10, 11, 12
	defb	21,  2,  8, 14	;sectors 13, 14, 15, 16
	defb	20, 26,  6, 12	;sectors 17, 18, 19, 20
	defb	18, 24,  4, 10	;sectors 21, 22, 23, 24
	defb	16, 22		;sectors 25, 26
;
dpblk:	;disk parameter block for all disks.
	defw	26		;sectors per track
	defb	3		;block shift factor
	defb	7		;block mask
	defb	0		;null mask
	defw	242		;disk size-1
	defw	63		;directory max
	defb	192		;alloc 0
	defb	0		;alloc 1
	defw	0		;check size
	defw	2		;track offset
;
;	end of fixed tables
;
;	individual subroutines to perform each function
boot:	;simplest case is to just perform parameter initialization
	XOR	a		;zero in the accum
	LD	(iobyte),A	;clear the iobyte
	LD	(cdisk),A	;select disk zero
	JP	gocpm		;initialize and go to cp/m
;
wboot:	;simplest case is to read the disk until all sectors loaded
	LD	sp, 80h		;use space below buffer for stack
	LD 	c, 0		;select disk 0
	call	seldsk
	call	home		;go to track 00
;
	LD 	b, nsects	;b counts * of sectors to load
	LD 	c, 0		;c has the current track number
	LD 	d, 2		;d has the next sector to read
;	note that we begin by reading track 0, sector 2 since sector 1
;	contains the cold start loader, which is skipped in a warm start
	LD	HL, ccp		;base of cp/m (initial load point)
load1:	;load	one more sector
	PUSH	BC		;save sector count, current track
	PUSH	DE		;save next sector to read
	PUSH	HL		;save dma address
	LD 	c, d		;get sector address to register C
	call	setsec		;set sector address from register C
	pop	BC		;recall dma address to b, C
	PUSH	BC		;replace on stack for later recall
	call	setdma		;set dma address from b, C
;
;	drive set to 0, track set, sector set, dma address set
	call	read
	CP	00h		;any errors?
	JP	NZ,wboot	;retry the entire boot if an error occurs
;
;	no error, move to next sector
	pop	HL		;recall dma address
	LD	DE, 128		;dma=dma+128
	ADD	HL,DE		;new dma address is in h, l
	pop	DE		;recall sector address
	pop	BC		;recall number of sectors remaining, and current trk
	DEC	b		;sectors=sectors-1
	JP	Z,gocpm		;transfer to cp/m if all have been loaded
;
;	more	sectors remain to load, check for track change
	INC	d
	LD 	a,d		;sector=27?, if so, change tracks
	CP	27
	JP	C,load1		;carry generated if sector<27
;
;	end of	current track,	go to next track
	LD 	d, 1		;begin with first sector of next track
	INC	c		;track=track+1
;
;	save	register state, and change tracks
	PUSH	BC
	PUSH	DE
	PUSH	HL
	call	settrk		;track address set from register c
	pop	HL
	pop	DE
	pop	BC
	JP	load1		;for another sector
;
;	end of	load operation, set parameters and go to cp/m
gocpm:
	LD 	a, 0c3h		;c3 is a jmp instruction
	LD	(0),A		;for jmp to wboot
	LD	HL, wboote	;wboot entry point
	LD	(1),HL		;set address field for jmp at 0
;
	LD	(5),A		;for jmp to bdos
	LD	HL, bdos	;bdos entry point
	LD	(6),HL		;address field of Jump at 5 to bdos
;
	LD	BC, 80h		;default dma address is 80h
	call	setdma
;
	ei			;enable the interrupt system
	LD	A,(cdisk)	;get current disk number
	cp	disks		;see if valid disk number
	jp	c,diskok	;disk valid, go to ccp
	ld	a,0		;invalid disk, change to disk 0
diskok:	LD 	c, a		;send to the ccp
	JP	ccp		;go to cp/m for further processing
;
;
;	simple i/o handlers (must be filled in by user)
;	in each case, the entry point is provided, with space reserved
;	to insert your own code
;   ;Edit by nsafran1217 for 16c550 UART
const:	;console status, return 0ffh if character ready, 00h if not
	in 	a,(UARTLSR)		    ;get status
	and 	0b00000001		;check RxRDY bit
	jp 	z,no_char
	ld	a,0ffh		        ;char ready	
	ret
no_char:
	ld	a,00h		    	;no char
	ret
;
conin:	;console character into register a
	IN A,(UARTLSR)		    ; Read LSR
	AND 0b00000001		    ; Check bit 0 (RHR byte ready)
	JP Z,conin              ; If zero, keep waiting for data
	IN A,(UART)	            ; Place ready character into A
	NOP						;; to line up bios correctly??
	NOP
	RET

;
conout:	;console character output from register c
    ld a,c                  ; move c to a so we can output it
    OUT (UART),A		    ; Send character to UART
conoutloop:
    IN A,(UARTLSR)          ; Read LSR
    AND 0b01000000          ; Check bit 6 (THR empty, line idle)
    JP Z,conoutloop
    RET
;
list:	;list character from register c
	LD 	a, c	  	;character to register a
	ret		  	;null subroutine
;
listst:	;return list status (0 if not ready, 1 if ready)
	XOR	a	 	;0 is always ok to return
	ret
;
punch:	;punch	character from	register C
	LD 	a, c		;character to register a
	ret			;null subroutine
;
;
reader:	;reader character into register a from reader device
	LD     a, 1ah		;enter end of file for now (replace later)
	AND    7fh		;remember to strip parity bit
	ret
;
;
;	i/o drivers for the disk follow
;	for now, we will simply store the parameters away for use
;	in the read and write	subroutines
;
home:	;move to the track 00	position of current drive
;	translate this call into a settrk call with Parameter 00
	LD     c, 0		;select track 0
	call   settrk
	ret			;we will move to 00 on first read/write
;
seldsk:	;select disk given by register c
	LD	HL, 0000h	;error return code
	LD 	a, c
	LD	(diskno),A
	CP	disks		;must be between 0 and 3
	RET	NC		;no carry if 4, 5,...
;	disk number is in the proper range
;	defs	10		;space for disk select
;	compute proper disk Parameter header address
	LD	A,(diskno)
	LD 	l, a		;l=disk number 0, 1, 2, 3
	LD 	h, 0		;high order zero
	ADD	HL,HL		;*2
	ADD	HL,HL		;*4
	ADD	HL,HL		;*8
	ADD	HL,HL		;*16 (size of each header)
	LD	DE, dpbase
	ADD	HL,DE		;hl=,dpbase (diskno*16) Note typo here in original source.
	ret
;
settrk:	;set track given by register c
	LD 	a, c
	LD	(track),A
	ret
;
setsec:	;set sector given by register c
	LD 	a, c
	LD	(sector),A
	ret
;
;
sectran:
	;translate the sector given by bc using the
	;translate table given by de
	EX	DE,HL		;hl=.trans
	ADD	HL,BC		;hl=.trans (sector)
	ret			;debug no translation
	LD 	l, (hl)		;l=trans (sector)
	LD 	h, 0		;hl=trans (sector)
	ret			;with value in hl
;
setdma:	;set	dma address given by registers b and c
	LD 	l, c		;low order address
	LD 	h, b		;high order address
	LD	(dmaad),HL	;save the address
	ret
;
read:
;Read one CP/M sector from disk.
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read.
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
;
			ld	hl,hstbuf		;buffer to place disk sector (256 bytes)
rd_status_loop_1:	in	a,(IDESTATUS)			;check status
			and	80h			;check BSY bit
			jp	nz,rd_status_loop_1	;loop until not busy
rd_status_loop_2:	in	a,(IDESTATUS)			;check	status
			and	40h			;check DRDY bit
			jp	z,rd_status_loop_2	;loop until ready
			ld	a,01h			;number of sectors = 1
			out	(IDESECTORCOUNT),a			;sector count register
			ld	a,(sector)		;sector
			out	(IDELBABITS0TO7),a			;lba bits 0 - 7
			ld	a,(track)		;track
			out	(IDELBABITS8TO15),a			;lba bits 8 - 15
			ld	a,(diskno)		;disk (only bits 
			out	(IDELBABITS15TO23),a			;lba bits 16 - 23
			ld	a,11100000b		;LBA mode, select host drive 0
			out	(IDEDRIVEHEADREG),a			;drive/head register
			ld	a,20h			;Read sector command
			out	(IDESTATUS),a
rd_wait_for_DRQ_set:	in	a,(IDESTATUS)			;read status
			and	08h			;DRQ bit
			jp	z,rd_wait_for_DRQ_set	;loop until bit set
rd_wait_for_BSY_clear:	in	a,(IDESTATUS)
			and	80h
			jp	nz,rd_wait_for_BSY_clear
			in	a,(IDESTATUS)			;clear INTRQ
read_loop:		in	a,(IDEDATAREG)			;get data
			ld	(hl),a
			inc	hl
			in	a,(IDESTATUS)			;check status
			and	08h			;DRQ bit
			jp	nz,read_loop		;loop until clear
			ld	hl,(dmaad)		;memory location to place data read from disk
			ld	de,hstbuf		;host buffer
			ld	b,128			;size of CP/M sector
rd_sector_loop:		ld	a,(de)			;get byte from host buffer
			ld	(hl),a			;put in memory
			inc	hl
			inc	de
			djnz	rd_sector_loop		;put 128 bytes into memory
			in	a,(IDESTATUS)			;get status
			and	01h			;error bit
			ret

write:
;Write one CP/M sector to disk.
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read or write
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
			ld	hl,(dmaad)		;memory location of data to write
			ld	de,hstbuf		;host buffer
			ld	b,128			;size of CP/M sector
wr_sector_loop:		ld	a,(hl)			;get byte from memory
			ld	(de),a			;put in host buffer
			inc	hl
			inc	de
			djnz	wr_sector_loop		;put 128 bytes in host buffer
			ld	hl,hstbuf		;location of data to write to disk
wr_status_loop_1:	in	a,(IDESTATUS)			;check status
			and	80h			;check BSY bit
			jp	nz,wr_status_loop_1	;loop until not busy
wr_status_loop_2:	in	a,(IDESTATUS)			;check	status
			and	40h			;check DRDY bit
			jp	z,wr_status_loop_2	;loop until ready
			ld	a,01h			;number of sectors = 1
			out	(IDESECTORCOUNT),a			;sector count register
			ld	a,(sector)
			out	(IDELBABITS0TO7),a			;lba bits 0 - 7 = "sector"
			ld	a,(track)
			out	(IDELBABITS8TO15),a			;lba bits 8 - 15 = "track"
			ld	a,(diskno)
			out	(IDELBABITS15TO23),a			;lba bits 16 - 23, use 16 to 20 for "disk"
			ld	a,11100000b		;LBA mode, select drive 0
			out	(IDEDRIVEHEADREG),a			;drive/head register
			ld	a,30h			;Write sector command
			out	(IDESTATUS),a
wr_wait_for_DRQ_set:	in	a,(IDESTATUS)			;read status
			and	08h			;DRQ bit
			jp	z,wr_wait_for_DRQ_set	;loop until bit set			
write_loop:		ld	a,(hl)
			out	(IDEDATAREG),a			;write data
			inc	hl
			in	a,(IDESTATUS)			;read status
			and	08h			;check DRQ bit
			jp	nz,write_loop		;write until bit cleared
wr_wait_for_BSY_clear:	in	a,(IDESTATUS)
			and	80h
			jp	nz,wr_wait_for_BSY_clear
			in	a,(IDESTATUS)			;clear INTRQ
			and	01h			;check for error
			ret
;
;	the remainder of the cbios is reserved uninitialized
;	data area, and does not need to be a Part of the
;	system	memory image (the space must be available,
;	however, between"begdat" and"enddat").
;
track:	defs	2		;two bytes for expansion
sector:	defs	2		;two bytes for expansion
dmaad:	defs	2		;direct memory address
diskno:	defs	1		;disk number 0-15
;
;	scratch ram area for bdos use
begdat:	.equ	$	 	;beginning of data area
dirbf:	defs	128	 	;scratch directory area
all00:	defs	31	 	;allocation vector 0
all01:	defs	31	 	;allocation vector 1
all02:	defs	31	 	;allocation vector 2
all03:	defs	31	 	;allocation vector 3
chk00:	defs	16		;check vector 0
chk01:	defs	16		;check vector 1
chk02:	defs	16	 	;check vector 2
chk03:	defs	16	 	;check vector 3
;
enddat:	.equ	$	 	;end of data area
datsiz:	.equ	$-begdat;	;size of data area
hstbuf: ds	256		;buffer for host disk sector
	end