

;include this at very beginning under .org $0000 to copy code to ram, then disable rom, then copy back to $0000
;at the end of the file, put 
;code_end
;   end

        ld	hl,$0000	            ;start of code to transfer
        ld	bc,code_end-$0000+1	    ;length of code to transfer
        ld	de,$4000	            ;target of transfer
        ldir			            ;Z80 transfer instruction
        jp	$4000+disableRom

code_start:			
        JP MainPrompt                 ;Go to main menu

disableRom:
    LD C,$70                ;Load disable rom address
    LD B,$01                ;Load disable rom bit
    OUT (C),B               ;send bit

        ;copy back to $0000
        ld	hl,$4000	            ;start of code to transfer
        ld	bc,$4000+code_end-$0000+1	    ;length of code to transfer
        ld	de,$0000	            ;target of transfer
        ldir			            ;Z80 transfer instruction
        jp	Start