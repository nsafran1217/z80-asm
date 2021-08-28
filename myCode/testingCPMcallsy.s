    
DIVISOR = $0C
UART = $00
UARTLSR = $05   
RAMSTART = $5000 
DATALEN = $1000

IDESTATUS = $47
IDESECTORCOUNT = $42
IDELBABITS0TO7 = $43
IDELBABITS8TO15 = $44
IDELBABITS15TO23 = $45
IDEDRIVEHEADREG = $46
IDEDATAREG = $40
    
    
    .org $4000                  ;Our rom starts at $0000 to $3FFF
                                ;RAM from $4000 to $ffff
Setup:
        ;CALL testread
        ; Bring up OUT2 GPIO pin first, so we know things are starting like they're supposed to
        IN A,($04)
        OR %00001000            ;Bit 3 is GPIO2
        OUT ($04), A

        ; Set Divisor Latch Enable
        LD A,%10000000          ; Set Div Latch Enable to 1
        OUT ($03),A             ; Write LCR
        ; Set divisor to 12 (1.8432 MHz / 12 / 16 = 9600bps)
        LD A,DIVISOR
        OUT ($00),A             ; DLL 0x0C (#12)
        LD A,$00
        OUT ($01),A             ; DLM 0x00

        LD A,%00000011          ; Set DLE to 0, Break to 0, No parity, 1 stop bit, 8 bytes
        OUT ($03),A             ; Write now configured LCR

	LD SP,$ffff		        ; Initialise the stack pointer to $ff00 (it will grow DOWN in RAM)

        LD IY,splashScreen
        CALL PrintStr
   
        JP MainMenu             ;Go to main menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
disks:	.equ	04h		;number of disks in the system
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


        
;;CP/m IDE Disk Routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
setdma:			;set dma address given by registers b and c
        LD	l, c	;low order address
        LD	h, b	;high order address
        LD	(dmaad),HL 	;save the address
        ret
;
seldsk:			;select disk given by register c
        LD	HL, 0000h	;error return code
        LD	a, c
        LD	(diskno),A
        CP	disks	;must be between 0 and 3
        RET	NC	;no carry if 4, 5,...
;			disk number is in the proper range
;	defs	10	;space for disk select
;			compute proper disk Parameter header address
        LD	A,(diskno)
        LD	l, a	;l=disk number 0, 1, 2, 3
        LD	h, 0	;high order zero
        ADD 	HL,HL	;*2
        ADD	HL,HL	;*4
        ADD	HL,HL	;*8
        ADD	HL,HL	;*16 (size of each header)
        LD	DE, dpbase
        ADD	HL,DE	;hl=,dpbase (diskno*16). Note typo "DAD 0" here in original 8080 source.
        ret
;
settrk:			;set track given by register c
        LD	a, c
        LD	(track),A
        ret
;
setsec:			;set sector given by register c
        LD	a, c
        LD	(sector),A
        ret
;
;read:
;;Read one CP/M sector from disk.
;;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read.
;;Disk number in 'diskno'
;;Track number in 'track'
;;Sector number in 'sector'
;;Dma address in 'dmaad' (0-65535)
;;
;			ld	hl,hstbuf		;buffer to place disk sector (256 bytes)
;rd_status_loop_1:	in	a,(IDESTATUS)			;check status
;			and	80h			;check BSY bit
;			jp	nz,rd_status_loop_1	;loop until not busy
;rd_status_loop_2:	in	a,(IDESTATUS)			;check	status
;			and	40h			;check DRDY bit
;			jp	z,rd_status_loop_2	;loop until ready
;			ld	a,01h			;number of sectors = 1
;			out	(IDESECTORCOUNT),a			;sector count register
;			ld	a,(sector)		;sector
;			out	(IDELBABITS0TO7),a			;lba bits 0 - 7
;			ld	a,(track)		;track
;			out	(IDELBABITS8TO15),a			;lba bits 8 - 15
;			ld	a,(diskno)		;disk (only bits 
;			out	(IDELBABITS15TO23),a			;lba bits 16 - 23
;			ld	a,11100000b		;LBA mode, select host drive 0
;			out	(IDEDRIVEHEADREG),a			;drive/head register
;			ld	a,20h			;Read sector command
;			out	(IDESTATUS),a
;rd_wait_for_DRQ_set:	in	a,(IDESTATUS)			;read status
;			and	08h			;DRQ bit
;			jp	z,rd_wait_for_DRQ_set	;loop until bit set
;rd_wait_for_BSY_clear:	in	a,(IDESTATUS)
;			and	80h
;			jp	nz,rd_wait_for_BSY_clear
;			in	a,(IDESTATUS)			;clear INTRQ
;read_loop:		in	a,(IDEDATAREG)			;get data
;			ld	(hl),a
;			inc	hl
;			in	a,(IDESTATUS)			;check status
;			and	08h			;DRQ bit
;			jp	nz,read_loop		;loop until clear
;			ld	hl,(dmaad)		;memory location to place data read from disk
;			ld	de,hstbuf		;host buffer
;			ld	b,128			;size of CP/M sector
;rd_sector_loop:		ld	a,(de)			;get byte from host buffer
;			ld	(hl),a			;put in memory
;			inc	hl
;			inc	de
;			djnz	rd_sector_loop		;put 128 bytes into memory
;			in	a,(IDESTATUS)			;get status
;			and	01h			;error bit
;			ret
;
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


;;;;;;;;;;;;;;;;;;;;;;;;;
testwrite:
        LD A,0
        LD HL,$7000
        LD C,$E5
write_loop_test:
        
        
        LD (HL), C
        INC HL
        INC A
        CP 128
        JP NZ,write_loop_test

        LD C,0
        CALL seldsk


        LD C,0
        CALL settrk


        LD C,0
        CALL setsec


        LD B,$70
        LD C,$00
        CALL setdma

        CALL write

        CP 0
        JP Z,SuccessWrite
        CP 1
        JP Z,FailWrite
        JP MainMenu
testread:

        LD C,0
        CALL seldsk


        LD C,0
        CALL settrk


        LD C,0
        CALL setsec


        LD B,$80
        LD C,$80
        CALL setdma


        CALL read
        CP 0
        JP Z,SuccessRead
        CP 1
        JP Z,FailRead
        JP MainMenu

formatcpm:
        ld	a,00h	;starting disk
        ld	(disk),a
disk_loop:	ld	c,a	;CP/M disk a
        call 	seldsk
        ld	a,2	;starting track (offset = 2)
        ld	(track),a
track_loop:	ld	a,0	;starting sector
        ld	(sector),a
        ld	hl,directory_sector 	;address of data to write
        ld	(address),hl
        ld	a,(track)
        ld	c,a	;CP/M track
        call	settrk
sector_loop:	ld	a,(sector)
        ld	c,a	;CP/M sector
        call	setsec
        ld	bc,(address)	;memory location
        call	setdma
        call	write
        ld	a,(sector)
        cp	26
        jp	z,next_track
        inc	a
        ld	(sector),a
        jp	sector_loop
next_track:	ld	a,(track)
        cp	77
        jp	z,next_disk
        inc	a
        ld	(track),a
        jp	track_loop
next_disk:	ld	a,(disk)
        inc	a
        cp	4
        jp	z,done
        ld	(disk),a
        jp	disk_loop
done:	jp	MainMenu
disk:	db	00h
address:	dw	0000h
directory_sector = $7000

putsys:
;Copies the memory image of CP/M loaded at E400h onto tracks 0 and 1 of the first CP/M disk
;Load and run from ROM monitor
;Uses calls to BIOS, in memory at FA00h ;;doesnt in my verision
;Writes track 0, sectors 2 to 26, then track 1, sectors 1 to 25
;Put CPM in memory at $E400
;put BIOS at $FA00


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

;already defined;done:	jp	MainMenu

;address:	dw	0000h



SuccessRead:
        LD IY,SucMsgR
        CALL PrintStr
        JP MainMenu
FailRead:
        LD IY,FailMsgR
        CALL PrintStr
        JP MainMenu
SuccessWrite:
        LD IY,SucMsgW
        CALL PrintStr
        JP MainMenu
FailWrite:
        LD IY,FailMsgW
        CALL PrintStr
        JP MainMenu

PrintStr: ;Print a string indexed in IY
        PUSH AF
PrintStrLoop
        LD A,(IY)               ;LD into A value at address in IY
        CALL OutputChar         ;Output A
        INC IY                  ;INC IY, which is incrementing the address of the message
        LD A,(IY)               ;LD into A the next char to be printed
        CP $00                  ;Check if that char is 0. CP subtracts value from A but doesnt chnage A, only updates flags
        JP NZ,PrintStrLoop          ;If its not 0, go back to Alert and continue printing
        POP AF
        RET                     ;RETURN TO CALLER. VERY IMPORTANT
        

NewLine:
        LD IY,CRLF
        CALL PrintStr
        RET

MainMenu:
    
        LD IY,initMessage       ;Load message addrinto IY
        CALL PrintStr           ;Print message
        CALL Input               ;Wait for user Input
        CALL OutputChar         ;Echo char
        CP 'e'                  ;Is char e?
        JP Z, StartExecute4k    ;Yes, then StartExectuion
        CP 'v'                  ;Is char v?
        JP Z, ViewHexData
        CP 'l'
        JP Z, StartReadingData
        CP 'w'
        JP Z,WriteHexData
        CP 's'
        JP Z,StartExecuteAddr   ;specify address to execute from
        CP 'D'
        JP Z,DisableRom         ;go to disable rom subroutine
        CP 'k'
        JP Z,testread
        ;CP 'o'
        ;JP Z,testwrite
        ;cp 'f'                 ;disabling so i dont destory my disk
        ;JP Z,formatcpm
        cp 'c'
        JP Z,LOADCPM
        ;cp 'P'
        ;JP Z,putsys
        CP 'L'
        JP Z,LoadDataToAddress
        JP MainMenu             ;If none match, reprint the message
WriteHexData:
        JP MainMenu             ;Not implemented
        CALL AskForAddress      ;Get address from user
;Subroutine to read one disk sector (256 bytes)
;Address to place data passed in HL
;LBA bits 0 to 7 passed in C, bits 8 to 15 passed in B
;LBA bits 16 to 23 passed in E
disk_read:
rd_status_loop_1:	in	a,(IDESTATUS)		;check status
			and	80h		;check BSY bit
			jp	nz,rd_status_loop_1	;loop until not busy
rd_status_loop_2:	in	a,(IDESTATUS)		;check	status
			and	40h		;check DRDY bit
			jp	z,rd_status_loop_2	;loop until ready
			ld	a,01h		;number of sectors = 1
			out	(IDESECTORCOUNT),a		;sector count register
			ld	a,c
			out	(IDELBABITS0TO7),a		;lba bits 0 - 7
			ld	a,b
			out	(IDELBABITS8TO15),a		;lba bits 8 - 15
			ld	a,e
			out	(IDELBABITS15TO23),a		;lba bits 16 - 23
			ld	a,11100000b	;LBA mode, select drive 0
			out	(IDEDRIVEHEADREG),a		;drive/head register
			ld	a,20h		;Read sector command
			out	(IDESTATUS),a
rd_wait_for_DRQ_set:	in	a,(IDESTATUS)		;read status
			and	08h		;DRQ bit
			jp	z,rd_wait_for_DRQ_set	;loop until bit set
rd_wait_for_BSY_clear:	in	a,(IDESTATUS)
			and	80h
			jp	nz,rd_wait_for_BSY_clear
			in	a,(IDESTATUS)		;clear INTRQ
read_loop:		in	a,(IDEDATAREG)		;get data
			ld	(hl),a
			inc	hl
			in	a,(IDESTATUS)		;check status
			and	08h		;DRQ bit
			jp	nz,read_loop	;loop until cleared
			ret
;;It uses the ROM monitor disk_read subroutine that takes BC and E as the LBA, and HL as the memory area to write to
LOADCPM:
        LD SP,$80
        

;Retrieves CP/M from disk and loads it in memory starting at E400h
;Uses calls to ROM subroutine for disk read.
;Reads track 0, sectors 2 to 26, then track 1, sectors 1 to 25
;This program is loaded into LBA sector 0 of disk, read to loc. 0800h by ROM disk_read subroutine, and executed.
;
;hstbuf:	.equ	0900h	;will put 256-byte raw sector here
cpm:	.equ	0FA00h	;CP/M cold start entry in BIOS

        ;Read track 0, sectors 2 to 26
        ld	a,2	;starting sector -- sector 1 reserved
        ld	(sector),a
        ld	hl,0E400h	;memory address -- start of CCP
        ld	(dmaad),hl
        ld	a,0	;CP/M track
        ld	(track),a
rd_trk_0_loop: 	call 	read
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
rd_trk_1:	ld	a,1
        ld	(track),a
        ld	hl,(dmaad)
        ld	de,128
        add 	hl,de
        ld	(dmaad),hl
        ld	a,1	;starting sector
        ld	(sector),a
rd_trk_1_loop: 	call	read
        ld	a,(sector)
        cp	25
        jp	z,doneCPMLOAD
        inc	a
        ld	(sector),a
        ld	hl,(dmaad)
        ld	de,128
        add	hl,de
        ld	(dmaad),hl
        jp	rd_trk_1_loop
doneCPMLOAD:
        JP MainMenu
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
rd_sector_loop: 	ld	a,(de)	;get byte from host buffer
        ld	(hl),a	;put in memory
        inc	hl
        inc	de
        djnz 	rd_sector_loop 	;put 128 bytes into memory
        in	a,(IDESTATUS)	;get status
        and	01h	;error bit
        ret



ViewHexData:
        CALL AskForAddress      ;Get address from user
        CALL OutputHexData      ;output $80 data starting at HL
        JP MainMenu

LoadDataToAddress:
        CALL AskForAddress
        PUSH HL
        CALL AskForDataLen
        LD D,H
        LD E,L
        POP HL
        LD IY,beginLoadMessage       ;Load message address into index register IY
        CALL PrintStr           ;Print the message
        JP ReadDataLoop

StartReadingData:
        LD IY,loadMessage       ;Load message address into index register IY
        CALL PrintStr           ;Print the message
        LD HL,RAMSTART          ;Load starting ram address into HL
        LD DE,DATALEN           ;Load length of data into DE
ReadDataLoop:			; Main read/write loop
	CALL Input		; Read a byte from serial terminal
        ;CALL Output
        CALL StoreInRam
        DEC DE                  ;decrement bytes left to read
        LD A,D                  ;ld highbyte of DE into A
        CP $00                  ;check if zero
	JP NZ, ReadDataLoop         ;if not keep looping
        LD A,E                  ;ld low byte of DE into A
        CP $00                  ;check if zero
        JP NZ, ReadDataLoop         ;if not keep looping
        ;if it is, Go back to main menu and print Message
        LD IY,dataLoadedMessage
        CALL PrintStr
        JP MainMenu

StartExecute4k:
        CALL NewLine
        LD HL,RAMSTART          ;Set ram address back to start
        JP (HL)                 ;And start exectuon there

StartExecuteAddr:
        CALL NewLine
        CALL AskForAddress      ;Get addr from user
        CALL NewLine
        JP (HL)                 ;And start exectuon there

DisableRom:
        PUSH BC
        LD C,$70                ;Load disable rom address
        LD B,$01                ;Load disable rom bit
        OUT (C),B               ;send bit
        POP BC
        JP MainMenu       
;;Gets datalen in hex. stores value in HL
AskForDataLen:
        LD IY,WhatDataLenMessage   
        CALL PrintStr 
        LD D,$04                ;Get 4 charcters
        LD HL,$0000
        JP AskForHexLoop

;;Asks user to input hex address, stores in HL Destorys all registers
AskForAddress:
        LD IY,WhatAddrMessage   
        CALL PrintStr 
        LD D,$04                ;Get 4 charcters
        LD HL,$0000
AskForHexLoop:   
        CALL Input
        CALL OutputChar
        ;;LD A,B                ;;we now use A for input and output
        CALL ATOHEX             ;Convert hex ascii to real number
        PUSH AF                 ;push value to stack
        DEC D                   ;Dec char counter
        LD A,D                  ;Move D to A
        CP $00                  ;Is 0?
        JP NZ,AskForHexLoop ;Keep going if we need more CHARS

        POP AF                  ;get low nibble
        LD B,A                  ;put into B
        POP AF                  ;get high nibble
        RLC A                   ;shift nibble left 4 times
        RLC A
        RLC A
        RLC A
        OR B                    ;or with low nibble

        LD L,A                  ;load low byte 
 
        POP AF
        LD B,A
        POP AF
        RLC A
        RLC A
        RLC A
        RLC A
        OR B
        LD H,A                  ;load high byte 
        RET


ResetD:
    LD D,$00
    RET
;;Output $80 address in a table starting at address in HL. Destorys all registers
OutputHexData:
        CALL NewLine
        ;;LD HL,RAMSTART          ;Set ram address back to start
        LD E,$80                ;Load length of data  to display into D
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte
        LD A,'-'
        CALL OutputChar
        PUSH HL                 ;Push HL to retrieve later. This contains the real address we need

        ADC HL,DE               ;16 bit add
              
        LD A,H                  ;display highbyte
        CALL hexout
        LD A,L
        CALL hexout             ;display lowbyte

        POP HL                  ; restore HL to the real address
        CALL NewLine
        CALL ResetD
OutputHexLoop:
        LD A,(HL)
        CALL hexout             ;print A as hex char
        LD A,' '
        CALL OutputChar
        INC HL                  ;Inc ram address
        DEC E                   ;Dec address left to display
        INC D                   ;Inc number display per line
        LD A,D                  ;Check is we've printed 16 bytes
        CP $10                  
        CALL Z, NewLine         ;If we did do a new line and reset the counter
        CALL Z, ResetD
        LD A,E                  ;ld count of bytes left to display
        CP $00                  ;check if zero
        JP NZ, OutputHexLoop    ;if not keep displaying


        LD IY,KeepPrintMessage  ;Ask if user wants to view more hex
        CALL PrintStr           ;Print
        CALL Input
        LD E,$80                ;Reset D incase we want to print more
        ;LD A,B                  ;;we now use A for input and output
        CP 'c'                  ;is input C?
        JP Z,OutputHexData      ;Yes, print more hex,
        RET                     ;else, go back
               

StoreInRam:                     ;Store A into RAM at HL. This increments HL
        LD (HL),A               ;Load A into address HL points to
        INC HL                  ; INC HL to next address
        RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; OUTPUT VALUE OF A IN HEX ONE NYBBLE AT A TIME
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
hexout:
    	PUSH BC
		PUSH AF
		LD B, A
		; Upper nybble
		SRL A
		SRL A
		SRL A
		SRL A
		CALL TOHEX


        CALL OutputChar

		
		; Lower nybble
		LD A, B
		AND 0FH
		CALL TOHEX


		CALL OutputChar

		
		POP AF
		POP BC
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; TRANSLATE value in lower A TO 2 HEX CHAR CODES FOR DISPLAY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
TOHEX:
		PUSH HL
		PUSH DE
		LD D, 0
		LD E, A
		LD HL, DATA
		ADD HL, DE
		LD A, (HL)
		POP DE
		POP HL
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 	ASCII char code for 0-9,A-F in A to single hex digit
;;    subtract $30, if result > 9 then subtract $7 more
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ATOHEX:
		SUB $30
		CP 10
		RET M		; If result negative it was 0-9 so we're done
		SUB $7		; otherwise, subtract $7 more to get to $0A-$0F
		RET		

;;CP/M con subroutines
const:	;console status, return 0ffh if character ready, 00h if not
	in 	a,(UARTLSR)		;get status
	and 	0b00000001		;check RxRDY bit
	jp 	z,no_char
	ld	a,0ffh		;char ready	
	ret
no_char:
        ld	a,00h		;no char
	ret
;
conin:	;console character into register a
	IN A,(UARTLSR)		; Read LSR
	AND 0b00000001		        ; Check bit 0 (RHR byte ready)
	JP Z,conin              ; If zero, keep waiting for data
	IN A,(UART)	        ; Place ready character into A
	RET

;
conout:	;console character output from register c
        ld c,a                  ; move c to a so we can output it
        OUT (UART),A		; Send character to UART
conoutloop:
        IN A,(UARTLSR)          ; Read LSR
        AND 0b01000000          ; Check bit 6 (THR empty, line idle)
        JP Z,conoutloop
        RET
	
;
;; Take a character in register A and output to the UART, toggling the GPIO LED
OutputChar:
        PUSH AF
        PUSH BC
        call     conout
        POP BC
        POP AF

        RET

;; Read a character from the UART and place in register A
Input:
        CALL conin
        RET

splashScreen: .asciiz "\r\n\r\nWelcome to Z80 ROM MONITOR\r\n (c)Nathan Safran 2021\r\n\r\n\r\n"
initMessage: .asciiz "\r\nEnter l to load data into RAM\r\nEnter L to load data to specified address\r\nEnter v to view a HEX address\r\nEnter w to write value to address\r\nPress e to jump execution to $4000\r\nEnter s to jump execution to specified address\r\nEnter D to disable ROM\r\npress o to test write data\r\npress k to test read data. places at $8080\n\rpress f to format disk. press o first\r\npress P to putsys\r\nc to load cp/m. DISABLE ROM FIRST\r\n:"
loadMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000\r\nYou may have to send 1 more byte after loading\r\nReady to load:\r\n"   ;needs the -esc option to treat these as cr and lf
beginLoadMessage: .asciiz "\r\nBegin sending data\r\n"
;;initMessage: .asciiz "test"
dataLoadedMessage: .asciiz "\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\nData has been loaded into RAM\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\n"
CRLF: .asciiz "\r\n"
KeepPrintMessage: .asciiz"\r\nPress c to continue printing\r\nPress any key to return to menu\r\n"
WhatAddrMessage: .asciiz "\r\nEnter address in HEX. Capital letters only\r\n"
WhatDataLenMessage: .asciiz "\r\nEnter data length in HEX. Capital letters only\r\n"
SucMsgR: .asciiz "\r\n\r\nRead Data\r\n\r\n"
FailMsgR: .asciiz "\r\n\r\nFAIL Read Data\r\n\r\n"
SucMsgW: .asciiz "\r\n\r\nWROTE Data\r\n\r\n"
FailMsgW: .asciiz "\r\n\r\nFAIL Write Data\r\n\r\n"

DATA:
		DEFB	30h	; 0
		DEFB	31h	; 1
		DEFB	32h	; 2
		DEFB	33h	; 3
		DEFB	34h	; 4
		DEFB	35h	; 5
		DEFB	36h	; 6
		DEFB	37h	; 7
		DEFB	38h	; 8
		DEFB	39h	; 9
		DEFB	41h	; A
		DEFB	42h	; B
		DEFB	43h	; C
		DEFB	44h	; D
		DEFB	45h	; E
		DEFB	46h	; F

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

hstbuf: ds	256		;buffer for host disk sector
    .org $4ffe

    .word $0000