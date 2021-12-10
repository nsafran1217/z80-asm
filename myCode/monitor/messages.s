
splashScreen: .asciiz "\r\n\r\nZ80 ROM MONITOR v2.0\r\n(c)Nathan Safran 2021\r\nBuild Date 9-DEC-2021\r\n\r\n"

loadMessage: .asciiz "\r\nSend a program up to 4k Bytes\n\r.org should be $4000. Pad until $5000S\r\nReady to load:\r\n"   ;needs the -esc option to treat these as cr and lf

beginLoadMessage: .asciiz "\r\nBegin sending data:\r\n"

dataLoadedMessage: .asciiz "\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\nData has been loaded into RAM\r\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\r\n"

KeepPrintMessage: .asciiz"\r\nPress SPACE BAR to continue printing\r\nPress any key to return to menu\r\n"


ReadWriteDataToHDDMSG: .asciiz "\r\nEnter the following data in HEX caps only (4 Digits each):\r\nTrack\r\nSector\r\nDisk\r\nAddress to read/write data\r\n"
AreYouSureMsg: .asciiz "\r\nAre you sure? This can destoy data.\r\nEnter Y to continue, any key to go back to menu\r\n:"



InvalidCommandMSG:  .asciiz "\r\nInvalid Command -- "

HelpMSG:        
    .text "\r\nUse all CAPS."
    .text "\r\n\r\n\033[1mHELP\033[0m  -- Display this message\r\n"
    .text "\r\n\r\n\033[1mBEEP\033[0m  -- Beep"
    .text "\r\n\r\n\033[1mRESET\033[0m -- JP to $0000"
    .text "\r\n\033[1mREAD\033[0m  -- Read value at address."
    .text "\r\n\tARGS:"
    .text "\r\n\t1st Arg:Address, 4 digit $HEX number"
    .text "\r\n\r\n\033[1mDUMP\033[0m  -- DUMP $80 values at address."
    .text "\r\n\tARGS:"
    .text "\r\n\t1st Arg:Address, 4 digit $HEX number"
    .text "\r\n\r\n\033[1mWRITE\033[0m -- Write Value to address"
    .text "\r\n\tARGS:"
    .text "\r\n\t1st Arg:Address, 4 digit $HEX number."
    .text "\r\n\t2nd Arg:Data, 2 digit $HEX number"
    .text "\r\n\r\n\033[1mLOAD\033[0m  -- Load data from serial to address."
    .text "\r\n\tARGS:"
    .text "\r\n\t1st Arg(opt):Address, 4 digit $HEX number($4000 default)."
    .text "\r\n\t2nd Arg(opt):Data Length, 4 digit $HEX number($1000 defualt)"
    .asciiz "\r\n"



;\033[1m
;intense
;\033[0m
;reset