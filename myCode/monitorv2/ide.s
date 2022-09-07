IDESTATUS = $47
IDESECTORCOUNT = $42
IDELBABITS0TO7 = $43
IDELBABITS8TO15 = $44
IDELBABITS15TO23 = $45
IDEDRIVEHEADREG = $46
IDEDATAREG = $40
;Subroutine to read one disk sector (256 bytes)
;Address to place data passed in HL
;LBA bits 0 to 7 passed in C, bits 8 to 15 passed in B
;LBA bits 16 to 23 passed in E
disk_read:
rd_status_loop_1:	
        in	a,(IDESTATUS)		;check status
        and	80h		        ;check BSY bit
        jp	nz,rd_status_loop_1	;loop until not busy
rd_status_loop_2:	
        in	a,(IDESTATUS)		;check	status
        and	40h		        ;check DRDY bit
        jp	z,rd_status_loop_2	;loop until ready
        ld	a,01h		        ;number of sectors = 1
        out	(IDESECTORCOUNT),a	;sector count register
        ld	a,c
        out	(IDELBABITS0TO7),a	;lba bits 0 - 7
        ld	a,b
        out	(IDELBABITS8TO15),a	;lba bits 8 - 15
        ld	a,e
        out	(IDELBABITS15TO23),a	;lba bits 16 - 23
        ld	a,11100000b	        ;LBA mode, select drive 0
        out	(IDEDRIVEHEADREG),a	;drive/head register
        ld	a,20h		        ;Read sector command
        out	(IDESTATUS),a
rd_wait_for_DRQ_set:	
        in	a,(IDESTATUS)		;read status
        and	08h		        ;DRQ bit
        jp	z,rd_wait_for_DRQ_set	;loop until bit set
rd_wait_for_BSY_clear:	
        in	a,(IDESTATUS)
        and	80h
        jp	nz,rd_wait_for_BSY_clear
        in	a,(IDESTATUS)		;clear INTRQ
read_loop:
        in      a,(IDEDATAREG)          ;get data
        ld	(hl),a
        inc	hl
        in	a,(IDESTATUS)		;check status
        and	08h		        ;DRQ bit
        jp	nz,read_loop	        ;loop until cleared
        ret

;
;Subroutine to write one disk sector (256 bytes)
;Address of data to write to disk passed in HL
;LBA bits 0 to 7 passed in C, bits 8 to 15 passed in B
;LBA bits 16 to 23 passed in E
disk_write:
wr_status_loop_1:	
        in	a,(IDESTATUS)		        ;check status
        and	80h		        ;check BSY bit
        jp	nz,wr_status_loop_1	;loop until not busy
wr_status_loop_2:	
        in	a,(IDESTATUS)		        ;check	status
        and	40h		        ;check DRDY bit
        jp	z,wr_status_loop_2	;loop until ready
        ld	a,01h		        ;number of sectors = 1
        out	(IDESECTORCOUNT),a	 ;sector count register
        ld	a,c
        out	(IDELBABITS0TO7),a      ;lba bits 0 - 7
        ld	a,b
        out	(IDELBABITS8TO15),a     ;lba bits 8 - 15
        ld	a,e
        out	(IDELBABITS15TO23),a    ;lba bits 16 - 23
        ld	a,11100000b	        ;LBA mode, select drive 0
        out	(IDEDRIVEHEADREG),a     ;drive/head register
        ld	a,30h		        ;Write sector command
        out	(IDESTATUS),a
wr_wait_for_DRQ_set:	
        in	a,(IDESTATUS)           ;read status
        and	08h		        ;DRQ bit
        jp	z,wr_wait_for_DRQ_set	;loop until bit set			
write_loop:		
        ld	a,(hl)
        out	(IDEDATAREG),a          ;write data
        inc	hl
        in	a,(IDESTATUS)           ;read status
        and	08h		        ;check DRQ bit
        jp	nz,write_loop	        ;write until bit cleared
wr_wait_for_BSY_clear:	
        in	a,(IDESTATUS)
        and	80h
        jp	nz,wr_wait_for_BSY_clear
        in	a,(IDESTATUS)           ;clear INTRQ
        ret

