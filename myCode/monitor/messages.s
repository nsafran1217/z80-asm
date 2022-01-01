
splashScreen: .asciiz "\r\n\r\nZ80 ROM MONITOR v2.0\r\n(c)Nathan Safran 2021\r\nBuild Date 31-DEC-2021\r\n\r\n"

loadMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000S\r\nReady to load:\r\n"   ;needs the -esc option to treat these as cr and lf

beginLoadMessage: .asciiz "\r\nBegin sending data:\r\n"

dataLoadedMessage: .asciiz "\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\nData has been loaded into RAM\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\n"

KeepPrintMessage: .asciiz"\r\nPress SPACE BAR to continue printing\r\nPress any key to return to menu\r\n"

WhatAddrMessage: .asciiz "\r\nEnter address in HEX. Capital letters only. 4 digits\r\n:"
WhatDataLenMessage: .asciiz "\r\nEnter data length in HEX. Capital letters only, 4 digits\r\n:"
WhatValMessage: .asciiz "\r\nEnter value to write in HEX. Capital letters only,\r\n 4 digits, put 00 for high nybble\r\n:"

ReadWriteDataToHDDMSG: .asciiz "\r\nEnter the following data in HEX caps only (4 Digits each):\r\nTrack\r\nSector\r\nDisk\r\nAddress to read/write data\r\n"
AreYouSureMsg: .asciiz "\r\nAre you sure? This can destoy data.\r\nEnter Y to continue, any key to go back to menu\r\n:"

MainMenuMSG: 
    .text "\r\n"
    .text "Enter l to load data into RAM at 4k"
    .text "\r\n"
    .text "Enter L to load data to specified address"
    .text "\r\n"
    .text "Enter v to view a HEX address"
    .text "\r\n"
    .text "Enter w to write value to address"
    .text "\r\n"
    .text "Enter r to read value at address"
    .text "\r\n"
    .text "Press e to jump execution to $4000"
    .text "\r\n"
    .text "Enter s to jump execution to specified address"
    .text "\r\n"
    .text "Enter C to Start CP/M"
    .text "\r\n"
    .text "Enter H to enter HDD menu"
    .text "\r\n"
    .text "Enter F to enter FDD menu"
    .text "\r\n"
    .text "Enter R to soft restart"
    .text "\r\n"
    .byte ":"
    .byte 0

HDDMenuMSG: 
    .text "\r\n"
    .text "Enter R to read data from HDD"
    .text "\r\n"
    .text "Enter W to write data to HDD"
    .text "\r\n"
    .byte ":"
    .byte 0

FDDMenuMSG: 
    .text "\r\n"
    .text "Enter R to read data from Floppy"
    .text "\r\n"
    .text "Enter W to write data to Floppy"
    .text "\r\n"
    .byte ":"
    .byte 0




;\033[1m
;intense
;\033[0m
;reset