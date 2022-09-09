    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
 
  IN A,($04)		; Read the MCR into the Accumulator
  OR %00001100		; Make sure the /OUT2 GPIO pin in the bitmask is on
  OUT ($04),A		; Write the bitmask back out to the MCR, enabling our change

  LD A,%10000000	; Bitmask to set the DLE to 1
  OUT ($03),A		; Write the mask to the LCR (register $03)

  LD A,$0C		; 12
  OUT ($00),A		; Write 12 to the DLL
  LD A,$00		; 00
  OUT ($01),A		; Write 00 to the DLM - thus giving us a final divisor of $000C, or 12

  LD A,%00000011	; Bitmask to set DLE back to 0, and configure the LCR for 8, N, 1
  OUT ($03),A		; Write to the LCR

  LD C,$00		; Put the THR address in the C register
  LD B,'A'		; Load the ASCII character 'A' in the B register

Output:
  IN A,($04)		; Read the MCR
  XOR %00000100		; Toggle the /OUT1 pin
  OUT ($04),A		; Write back to the MCR

  OUT (C),B		; Push the contents of the B register ("A") out to the address in the C register ($00)
  INC B			; Increment the letter in the B register
  LD A,'['		; The character after Z in the ASCII character map is the left square bracket, load this into A
  CP B			; Compare to B
  JP Z,ResetByte	; If they are the same (B is also '['), jump to ResetByte

Loop:
  IN A,($05)		; Read the LSR
  BIT 6,A		; Check bit 6 on the byte read from the LSR
  JP Z,Loop		; If zero, loop
  JP Output		; Elsewise, go back to outputting the next character

ResetByte:
  LD B,'A'		; Put an ASCII 'A' back into B
  JP Loop		; Jump back to the LSR polling loop  
  