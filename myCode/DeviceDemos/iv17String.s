;Subroutines to print out strings to the iv17 display
;Scrolling, static printing, etc
;NumOfVFDTubes and ScrollSpeed must be provided
;
;Blank the display
BlankDisplay:
    PUSH BC
    PUSH AF
    LD B, NumOfVFDTubes   ;Number of blanks to shift out
    LD A, 0
BlankDisplayLoop:
    CALL ShiftOutChar
    DJNZ BlankDisplayLoop
    CALL StrobeDisplay      ;Strobe when done
    POP AF
    POP BC
    RET


;Scroll a NUL Terminated string of UP TO 64 characters pointed to by HL
;Will scroll right to left. Blank spaces will follow the string
;Display will be empty after the string is scrolled
;For now, we will use WAIT_4 for the delay. I need a hardware timer...
;HL destroyed
ScrollOutString:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL


    LD B,NumOfVFDTubes
    LD HL, ScrollMessageBuffer
    LD A, 0
AddBlanksToStringStart:
    LD (HL), A
    INC HL
    DJNZ AddBlanksToStringStart
    PUSH HL                     ;Move HL into DE and bring HL back to original value
    POP DE                      ;DE is pointing to our string buffer ready to take characters
    POP HL                      ;HL is pointing to the beginning of the string
CopyStringToBuffer:
    LDI                         ;LD (DE), (HL), INC both, and DEC BC, but we dont care about BC right now
    LD A, (HL)                  ;We need to check if we hit the NUL
    CP 0
    JP NZ, CopyStringToBuffer   ;If not, keep copying
    ;Once we hit the NUL, we need to add NumOfTubes more NULs
    PUSH DE
    POP HL                      ;Get DE into HL. We're done with the orignial string pointer
    LD B, NumOfVFDTubes-1
    LD A, 0
AddBlanksToStringEnd:
    LD (HL), A
    INC HL
    DJNZ AddBlanksToStringEnd
    ;At this point, memory is setup, but we kinda need to know how long the string is. 
    ;plus how many NULs are at the start and end
    ;So we could just go until we hit NumOfTubes NUL in a row
    ;Lets try that first
    LD B,  NumOfVFDTubes+1      ;Number of NULs that should be at the start and end
                                ;Because HL is only pointing at a NUL once at the end and NumOfTubes at the start
    LD HL, ScrollMessageBuffer
ScrollStringWindowLoop:         ;We need a loop where we INC HL and display that string 
    LD DE, ScrollSpeed
    CALL WaitLoop
    CALL ShiftOutStringTubeLen
    LD A, (HL)
    CP 0                        ;Is it a NUL at the string we just shifted?
    JP Z, DecCounterOfNULs
    INC HL                      ;Move window right
    JP ScrollStringWindowLoop
DecCounterOfNULs:
    INC HL
    DJNZ ScrollStringWindowLoop

    POP DE
    POP BC
    POP AF
    RET


;Shift out string equal to number of tubes. 
;Provide HL pointing to beginning of string
;Will move right = to number of tubes in memory
;Will shift out right to left
ShiftOutStringTubeLen:
    PUSH AF
    PUSH BC
    LD B, NumOfVFDTubes-1
ShiftOutStringTubeLenLoop1:
    INC HL
    DJNZ ShiftOutStringTubeLenLoop1
    LD B, NumOfVFDTubes
ShiftOutStringTubeLenLoop2:
    LD A, (HL)
    DEC HL
    CALL ShiftOutChar
    DJNZ ShiftOutStringTubeLenLoop2
    INC HL              ;Put HL back up to where it was at the very start
    CALL StrobeDisplay
    POP BC
    POP AF
    RET


;Shift out NULL terminatedstring pointed to by HL
ShiftOutStringNULTerm:
    PUSH AF
    PUSH BC
    LD B, 0
    ;Get to end of string (CP 0)
    ;Record this length
    ;Then we decrement through it
    ;shift out each character as we go.
    ;Will be aligned to the left of the display
    ;Would be way easier to scroll if I designed the hardware to shift in from the right to left...

FindNULLoop1:               ;Get the length of the string in B
    INC HL
    INC B                   ;Length of the string
    LD A, (HL)
    CP 0
    JP NZ, FindNULLoop1
ShiftOutStringNULLoop:
    DEC HL                  ;First character to shift out
    LD A, (HL)              ;Grab char
    CALL ShiftOutChar       ;shift it out
    DJNZ ShiftOutStringNULLoop ;Keep going until we have sent all chars

    CALL StrobeDisplay             ;Done, strobe the dispaly
    POP BC
    POP AF
    RET




;Wait loop from https://www.paleotechnologist.net/?p=2589
;Provide number of times to do loop in DE
;1 inner loop is about 6ms
WaitLoop:
   	push	AF
	push	BC
Outer:
    LD BC, 1000h            ;Loads BC with hex 1000
Inner:
    DEC BC                  ;Decrements BC
    LD A, B                 ;Copies D into A
    OR C                    ;Bitwise OR of E with A (now, A = D | E)
    JP NZ, Inner            ;Jumps back to Inner: label if A is not zero
    DEC DE                  ;Decrements DE
    LD A, D                 ;Copies B into A
    OR E                    ;Bitwise OR of C with A (now, A = B | C)
    JP NZ, Outer            ;Jumps back to Outer: label if A is not zero

	pop	BC
	pop	AF
	ret


ScrollMessageBuffer: .blk NumOfVFDTubes+64      ;Variable to store string. we will add blank characters to it
