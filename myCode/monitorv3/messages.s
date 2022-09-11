
splashScreen: .asciiz "\r\n\r\nZ80 ROM MONITOR v3.0\r\n(c)Nathan Safran 2021\r\nBuild Date 31-SEP-2022\r\n\r\n"

loadDefaultMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000"   ;needs the -esc option to treat these as cr and lf

beginLoadMessage: .asciiz "\r\nBegin sending data:\r\n"

dataLoadedMessage: .asciiz "\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\nData has been loaded into RAM\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\n"

OffsetMSG:  .asciiz "Off   "

WhatAddrMessage: .asciiz "\r\nEnter address in HEX. Capital letters only. 4 digits\r\n:"
WhatDataLenMessage: .asciiz "\r\nEnter data length in HEX. Capital letters only, 4 digits\r\n:"
WhatValMessage: .asciiz "\r\nEnter value to write in HEX. Capital letters only,\r\n 4 digits, put 00 for high nybble\r\n:"

ReadWriteDataToHDDMSG: .asciiz "\r\nEnter the following data in HEX caps only (4 Digits each):\r\nTrack\r\nSector\r\nDisk\r\nAddress to read/write data\r\n"
AreYouSureMsg: .asciiz "\r\nAre you sure? This can destoy data.\r\nEnter Y to continue, any key to go back to menu\r\n:"
InvalidCMDMsg: .asciiz "\r\nInvalid Command/Param. Enter H for help"
rPrompt:    .asciiz "\r:r "

HelpMSG: 
    .text "\r\n"
    .text "() - Required value | [] - Optional Value | {} - Default value if not entered"
    .text "\r\n********************************************************************************\r\n\n"
    .text ":L [$xxxx] [$xxxx] | Load data from COM to [address]{$4000} len [bytes]{$1000}"
    .text "\r\n"
    .text ":D [$xxxx] [$xxxx] | Dump [address] of len [bytes]{$0100}. Next addr default"
    .text "\r\n"
    .text ":W $xx [$xxxx]     | Write (value) to [address]. Write next address by default"
    .text "\r\n"
    .text ":R [$xxxx]         | Read value at [address]. Read next address by default"
    .text "\r\n"
    .text ":G [$xxxx]         | Jump execution to [address]{address from L cmd}"
    .text "\r\n"
    .text ":B                 | Enter Boot Menu"
    .text "\r\n"
    .text ":O $xx $xx         | Write (value) to (IO Port)"
    .text "\r\n"
    .text ":I $xx             | Read value from (IO Port)"
    .text "\r\n"
    .text ":Q                 | Ring Bell"
    .text "\r\n"
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