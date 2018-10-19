# How Z280RC Bootstrap from Compact Flash

This is the design description of cold boot software out of a compact flash.

The motivation is two folds. First is cost saving since a set of ROM is not required resulting in smaller pc board and fewer parts. Second is ease of programming that CF can easily reprogrammed in-situ.
## Introduction

This concept works the best for processor with 16-bit wide data bus because it matches with CF's native 16-bit data bus. At power up (or when reset button is pressed), a state machine (CFinit) holds the CPU in reset while configure the CF to read the boot sector (first sector of a CF disk). The boot sector contains a cold bootstrap code that copies a CF loader into memory and jump to it. After CF is configured to read the boot sector, the state machine also configure the memory map so memory location 0-0x1FF are mapped to the CF's data register where content of the boot sector will stream out with each CPU read. The state machine then negates CPU RESET and CPU begin fetch instruction starting from location 0. Because the CF data register is basically a 256 words deep FIFO that the cold bootstrap code must be written such that there are no looping. The state machine contains a register that can be cleared by software which will restore the memory map of 0-0x1FF to normal memory.
## CFinit State Machine

State Transition:

* read CF Status register bit 7 (BSY) & bit 6 (DRDY) until (BSY==0 AND DRDY==1)
* Write 0x1 to CF Sector Count register
* Write 0x1 to CF Sector register
* Write 0x0 to CF Cylinder Low register
* Write 0x0 to CF Cylinder High register
* Write 0x0 to CF Drive/Head register
* Write 0x20 (Read) to CF Command register
* Read CF Status register bit 7 (BSY) & bit 3 (DRQ) until (BSY==0 AND DRQ==1)
* Remap 0x0 - 0x1FF to CF Data register and Release RESET to Z280

## Cold Bootstrap Code

This is the code that will be in memory once cold bootstrap is done loading:

; This is the CFMon program that'll be created in 0xC000 by the CFMonLdr
CFdata       equ 0C0h        ;CF data register
CFerr        equ 0C2h        ;CF error reg
CFsectcnt    equ 0C5h        ;CF sector count reg
CF07         equ 0C7h        ;CF LA0-7
CF815        equ 0C9h           ;CF LA8-15
CF1623       equ 0CBh           ;CF LA16-23
CF2427       equ 0CDh           ;CF LA24-27
CFstat       equ 0CFh           ;CF status/command reg

     org 0C000h
     ld a,40h         ; LA addressing mode
     out (CF2427),a
     ld d,0f8h        ; points to sector to read, last 8 sectors in track 0
     ld hl,0b400h     ; store CF data starting from 0b400h
     ld c,CFdata      ; reg C points to CF data reg
moresect:
     ld a,1           ; read 1 sector
     out (CFsectcnt),a    ; write to sector count with 1
     ld a,d           ; read sector pointed by reg D
     cp 0feh          ; read sectors 0xF8-0xFD
     jp z,0b400h      ; load completed, run program loaded at 0xB400
     out (CF07),a     ; read the sector pointed by reg D
     ld a,20h         ; read sector command
     out (CFstat),a   ; issue the read sector command
readbsy:
     in a,(CFstat)    ; check bsy flag first
     and 80h          ; bsy flag is at bit 7
     jp nz,readbsy
readdrq:
     in a,(CFstat)    ; check data request bit set before read CF data
     and 8            ; bit 3 is DRQ, wait for it to set
     jp z,readdrq
     ld b,0h          ; sector has 256 16-bit data
     db 0edh,92h      ; op code for inirw input word and increment
;    inirw            ; reg HL and c are already setup at the top
     in a,(CFstat)    ; OUTJMP bug fix
     inc d
     jp moresect

This is the cold bootstrap code (https://github.com/Plasmode/Z280RC/blob/master/SystemSoftware/cfmonldr.zip) that executes the FIFO instruction stream from CF and creates the code above, byte-by-byte. It is strictly an in-line code with no looping and ends with a jump to the code just created.
