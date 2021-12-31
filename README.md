# z80-asm
Z80 assembly for custom computer
16c550 UART
16k ROM
48K RAM

$0000 - $3FFF - ROM on startup
$4000 - $FFFF - RAM, no bank switching

UART base address = $0x

IDE base Address - $4x

z80 PIO base address = $5x

Disable ROM address = $70
send $01 to disable ROM. Reboot to re-enable. I do not have a software reset yet

