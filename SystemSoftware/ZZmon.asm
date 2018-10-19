; 6/8/18 v0.99 fix xE command to clear RAMdisk at 0x80000 by writing 0xE5 to the directory
;  fill memory from top of program to 0xFFFF and from 0x0 to 0xAFFF
;  test memory from top of program to 0xFFFF and from 0x0 to 0xAFFF
; 5/19/18 v0.98 Relocate to 0xB400 so low memory can hold other applications
;  memory diagnostic will test 0x0-0xB1FF and then 0xC000-0xFFFF
;  Need to modify CFMon, CFMonLdr for different load address
;  Combine C0 and C1 command into one C0 command
;  C1 command will now copy program from 0x0 to 0x8000 to CF
;  B1 will copy program stored in CF to 0x0 to 0x8000 and jump to 0x0
;  Scratchpad area is now at 0xC000
;  Fill memory and clear memory affect 0x0-0xB1FF and 0xC000-0xFFFF
;  modify the xE command so to use page B and C instead of 0 and 1
; 4/16/18 v0.9 Modify the CFMon and CFMonLdr
;  Because the cold bootstrap code does not read all 512 bytes of boot sector before issue
;  read sector command to get ZZMon code, different brand of CF reacts differently to the aborted
;  operation.  Correct that by read the BSY flag first then read the DRQ flag before prceeding.
; 3/25/18 v0.8 move RAM disk directories to above 512K (0x80000), so the 'XE' command needs to
;  change
; 3/15/18 move ZZMon to 0x400 - 0xFFF, all the supporting software:
;    CFMon, CFMonLdr, TinyLoad, LoadnGo are changed as well.
; 3/10/18 Major revision
; This will be the core monitor to perform all functions related to TinyZ280
;  4 new write commands:
;    w0, writes the boot sector with the cold bootstrap code
;    w1, writes this program into last 8 sectors of track 0.  This program is 2K, but 4K reserved
;    w2, writes CP/M 2.2 into track 0, sector 128-146, assuming CPM2.2 is loaded into 0xDC00-0xFFFF
;    w3, writes CP/M 3 cpmldr into track 0, sectors after boot sectors, assuming the CP/M
;  new boot command:
;    b2, boot cpm2.2
;    b3, boot cpm3
; 2/15/18 Monitor for TinyZZ
; It resides in 4 sectors right after boot sector
; Derived from testCF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ZZMon, Copyright (C) 2018 Hui-chien Shen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UARTconf 	equ 10h		; UART configuration register
RxData  	equ 16h        	; on-chip UART receive register
TxData  	equ 18h        	; on-chip UART transmit register
RxStat  	equ 14h        	; on-chip UART transmitter status/control register
TxStat  	equ 12h        	; 0n-chip UART receiver status/control register

CFdata   	equ 0C0h    	;CF data register
CFerr    	equ 0C2h    	;CF error reg
CFsectcnt equ 0C5h    	;CF sector count reg
CF07     	equ 0C7h   	;CF LA0-7
CF815    	equ 0C9h       	;CF LA8-15
CF1623   	equ 0CBh       	;CF LA16-23
CF2427   	equ 0CDh       	;CF LA24-27
CFstat   	equ 0CFh       	;CF status/command reg
CFbootFF	equ 0A0h		;CF boot flip flop, initially set to 1
MMUctrl	equ 0f0h		; MMU master control reg
MMUptr	equ 0f1h		; MMU page descriptor reg pointer
MMUsel	equ 0f5h		; MMU descriptor select port
MMUmove	equ 0f4h		; MMU block move port
MMUinv	equ 0f2h		; MMU invalidation port
DMActrl	equ 01fh		; DMA master control reg
DMA2dstL	equ 10h		; DMA chan 2 destination reg low
DMA2dstH	equ 11h		; DMA chan 2 destination reg high
DMA2srcL	equ 12h		; DMA chan 2 source reg low
DMA2srcH	equ 13h		; DMA chan 2 source reg high
DMA2cnt	equ 14h		; DMA chan 2 count reg
DMA2td	equ 15h		; DMA chan 2 transaction descriptor
DMA3dstL	equ 18h		; DMA chan 3 destination reg low
DMA3dstH	equ 19h		; DMA chan 3 destination reg high
DMA3srcL	equ 1ah		; DMA chan 3 source reg low
DMA3srcH	equ 1bh		; DMA chan 3 source reg high
DMA3cnt	equ 1ch		; DMA chan 3 count reg
DMA3td	equ 1dh		; DMA chan 3 transaction descriptor

	ORG 0b400H		; when save to boot track
; Also relocate the stack when testing
	jp start
; variable area
refresho:	ds 1		; saved refresh register
refreshn: ds 1
testseed: ds 2		; RAM test seed value
addr3116	ds 2		; high address for Intel Hex format 4
;Initialization and sign-on message
start:
	ld sp,0bfffh	; initialize stack 

	ld c,08h		; reg c points to I/O page register
	ld l,0ffh		; set I/O page register to 0xFF
	db 0edh,6eh	; this is the op code for LDCTL (C),HL
;	ldctl (c),hl	; write to I/O page register
	in a,(0e8h)	; read the original refresh counter value
	ld (refresho),a	; save it
	ld a,0b0h		; initialize the refresh register to 48 counts
	out (0e8h),a	; enable refresh at 16uS
	in a,(0e8h)	; read back the counter value
	ld (refreshn),a	; save it
	ld l,0		; set I/O page reg to 0
	db 0edh,6eh	; this is the op code for LDCTL (C),HL
;	ldctl (c),hl	; write to I/O page register
	out (CFbootFF),a	; clear the CFbootFF with any write
	call UARTPage	; initialize page i/o reg to UART
	ld a,0e2h		; initialize the UART configuration register
	out (UARTconf),a
	ld a,80h		;enable UART transmit and receive
	out (TxStat),a
	out (RxStat),a
    	LD HL,signon$
        	CALL STROUT
	ld hl,251		; initialize RAM test seed value
	ld (testseed),hl	; save it
clrRx:  
        	IN A,(RxStat)	; read on-chip UART receive status
        	AND 10H				;;Z data available?
        	jp z,CMD
        	IN A,(RxData)	; read clear the input buffer
	jp clrRx
;Main command loop
CMD:  	LD HL, PROMPT$
        	CALL STROUT
CMDLP1:
        	CALL CINQ
	cp ':'		; Is this Intel load file?
	jp z,initload
	cp 0ah		; ignore line feed
	jp z,CMDLP1
	cp 0dh		; carriage return get a new prompt
	jp z,CMD
	CALL COUT		; echo character
        	AND 5Fh
	cp 'H'		; help command
	jp z,HELP
        	CP A,'D'
        	JP Z,MEMDMP
        	CP A,'E'
        	JP Z,EDMEM
        	CP A,'G'
        	JP Z,go
	cp a,'R'		; read a CF sector
	jp z,READCF
	cp a,'Z'		; fill memory with zeros
	jp z,fillZ
	cp a,'F'		; fill memory with ff
	jp z,fillF
	cp a,'C'		; Copy to CF	
	jp z,COPYCF
	cp a,'T'		; testing RAM 
	jp z,TESTRAM
	cp 'B'		; boot CPM
	jp z,BootCPM
	cp 'X'		; clear RAMdisk directory at 0x80000
	jp z,format
what:
        	LD HL, what$
        	CALL STROUT
        	JP CMD
abort:
	ld hl,abort$	; print command not executed
	call STROUT
	jp CMD
; initialize for file load operation
initload:
	ld hl,0		; clear the high address in preparation for file load
	ld (addr3116),hl	; addr3116 modified with Intel Hex format 4 
; load Intel file
fileload:
	call GETHEXQ	; get two ASCII char (byte count) into hex byte in reg A
	ld d,a		; save byte count to reg D
	ld c,a		; save copy of byte count to reg C
	ld b,a		; initialize the checksum
	call GETHEXQ	; get MSB of address
	ld h,a		; HL points to memory to be loaded
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	call GETHEXQ	; get LSB of address
	ld l,a
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	call GETHEXQ	; get the record type, 0 is data, 1 is end
	cp 0
	jp z,filesave
	cp 1		; end of file transfer?
	jp z,fileend
	cp 4		; Extended linear address?
	jp nz,unknown	; if not, print a 'U'
; Extended linear address for greater than 64K
; this is where addr3116 is modified
	add a,b		; accumulating checksum of record type
	ld b,a		; checksum is kept in reg B
	ld a,d		; byte count should always be 2
	cp 2
	jp nz,unknown
	call GETHEXQ	; get first byte (MSB) of high address
	ld (addr3116+1),a	; save to addr3116+1
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
; Little Endian format.  MSB in addr3116+1, LSB in addr3116
	call GETHEXQ	; get the 2nd byte (LSB) of of high address
	ld (addr3116),a	; save to addr3116
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	call GETHEXQ	; get the checksum
	neg a		; 2's complement
	cp b		; compare to checksum accumulated in reg B
	jp nz,badload	; checksum not match, put '?'
	ld a,'E'		; denote a successful Extended linear addr update
	jp filesav2
;gggggggggggggggg gggggggggggg
; end of the file load
fileend:
	call GETHEXQ	; flush the line, get the last byte
	ld a,'X'		; mark the end with 'X'
	call COUT
	ld a,10			; carriage return and line feed
	call COUT
	ld a,13
	call COUT
	jp CMD
; the assumption is the data is good and will be saved to the destination memory
filesave:
	add a,b		; accumulating checksum of record type
	ld b,a		; checksum is kept in reg B
	ld ix,0c000h	; 0c000h is buffer for incoming data
filesavx:
	call GETHEXQ	; get a byte
	ld (ix),a		; save to buffer
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	inc ix
	dec d
	jp nz,filesavx
	call GETHEXQ	; get the checksum
	neg a		; 2's complement
	cp b		; compare to checksum accumulated in reg B
	jp nz,badload	; checksum not match, put '?'
	call DMAPage	; set page i/o reg to DMA
; use DMA to put data from buffer to location pointed by ehl
	push hl		; destination RAM in hl, save it for now
	ld b,0		; clear out MSB of reg BC, reg C contains the saved byte count
	push bc		; DMA count is in reg BC, save it 
; set up DMA master control
	ld c,DMActrl	; set up DMA master control
	ld hl,0f0e0h	; software ready for dma0&1, no end-of-process, no links
;	outw (c),hl	; write DMA master control reg
	db 0edh,0bfh	; op code for OUTW (C),HL
; set up DMA count register 
	ld c,DMA3cnt	; setup count of 128 byte
	pop hl		; transfer what was saved in bc into hl
;	outw (c),hl	; write DMA3 count reg
	db 0edh,0bfh	; op code for OUTW (C),HL
; source buffer starts at 0x1000
	ld c,DMA3srcH	; source is 0x1000
	ld hl,0cfh		; A23..A12 are 0x00c		
;	outw (c),hl	; write DMA3 source high reg
	db 0edh,0bfh	; op code for OUTW (C),HL
	ld c,DMA3srcL	;
	ld hl,0f000h	; A11..A0 are 0x0
;	outw (c),hl	; write DMA3 source low reg
	db 0edh,0bfh	; op code for OUTW (C),HL	
; destination buffer is in e + hl (saved in stack right now)
	ld c,DMA3dstH
	ld a,(addr3116)	; get A23..A16 value into reg H
	ld h,a		; 
	pop de		; restore saved hl into de
	ld l,d		; move A15..A8 value
	ld a,0fh		; force lowest nibble of DMA3dstH to 0xF
	or l
;	outw (c),hl	; write DMA3 destination high reg
	db 0edh,0bfh	; op code for OUTW (C),HL
	ld c,DMA3dstL
	ld h,d		; reg DE contain A15..A0 value
	ld l,e
	ld a,0f0h		; force highest nibble of DMA3dstL to 0xF
	or h
;	outw (c),hl	; write DMA3 destination low reg
	db 0edh,0bfh	; op code for OUTW (C),HL
; write DMA3 transaction description reg and start DMA
	ld hl,8080h	; enable DMA3, burst, byte size, flowthrough, no interrupt
;			;  incrementing memory for source & destination
	ld c,DMA3td	; setup DMA3 transaction descriptor reg
;	outw (c),hl	; write DMA3 transaction description reg
	db 0edh,0bfh	; op code for OUTW (C),HL
;  DMA should start now
	call UARTPage	; set page i/o reg to default

;filesav1:
;	call GETHEXQ	; get a byte
;	ld (hl),a		; save to destination
;	add a,b			; accumulating checksum
;	ld b,a			; checksum is kept in reg B
;	inc hl
;	dec d
;	jp nz,filesav1
;	call GETHEXQ	; get the checksum
;	neg a			; 2's complement
;	cp b				; compare to checksum accumulated in reg B
;	jp nz,badload	; checksum not match, put '?'
	ld a,'.'		; checksum match, put '.'
filesav2:
	call COUT
	jp flushln	; repeat until record end
badload:
	ld a,'?'		; checksum not match, put '?'
	jp filesav2
unknown:
	ld a,'U'		; put out a 'U' and wait for next record
	call COUT
flushln:
	call CINQ		; keep on reading until ':' is encountered
	cp ':'
	jp nz,flushln
	jp fileload
; format CF drives directories unless it is RAM disk
; drive A directory is track 1, sectors 0-0x1F
; drive B directory is track 0x40, sectors 0-0x1F
; drive C directory is track 0x80, sectors 0-0x1F
; drive D directory is track 0xC0, sectors 0-0x1F
format:
	ld hl,clrdir$	; command message
	call STROUT
	call CIN
	cp 'A'
	jp z,formatA	; fill track 1 sectors 0-0x1F with 0xE5
	cp 'B'
	jp z,formatB	; fill track 0x40 sectors 0-0x1F with 0xE5
	cp 'C'
	jp z,formatC	; fill track 0x80 sectors 0-0x1F with 0xE5
	cp 'D'
	jp z,formatD	; fill track 0xC0 sectors 0-0x1F with 0xE5
	cp 'E'
	jp z,ClearDir
	jp abort		; abort command if not in the list of options
formatA:
	ld de,100h	; start with track 1 sector 0
	jp doformat
formatB:
	ld de,4000h	; start with track 0x40 sector 0
	jp doformat
formatC:
	ld de,8000h	; start with track 0x80 sector 0
	jp doformat
formatD:
	ld de,0c000h	; start with track 0xC0 sector 0
doformat:
	ld hl,confirm$	; confirm command execution
	call STROUT
	call tstCRLF
	jp nz,abort	; abort command if not CRLF
	call CFPage	; initialize page i/o reg to CF
	ld a,40h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; MSB track is 0
	ld a,d		; reg D contains the track info
	out (CF815),a
	ld c,CFdata	; reg C points to CF data reg
	ld hl,0e5e5h	; value for empty directories
wrCFf:
	ld a,1		; write 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,e		; write CPM sector
	cp 20h		; format sector 0-0x1F
	jp z,wrCFdonef	; done formatting
	out (CF07),a	; 
	ld a,30h		; write sector command
	out (CFstat),a	; issue the write sector command
wrdrqf:
	in a,(CFstat)	; check data request bit set before write CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jp z,wrdrqf
	ld b,0h		; sector has 256 16-bit data
loopf:
	db 0edh,0bfh	; op code for OUT[W] (C),HL
;	outw (c),hl
	inc b
	jp nz,loopf
readbsyf:
; spin on CF status busy bit
	in a,(CFstat)	; read CF status 
	and 80h		; mask off all except busy bit
	jp nz,readbsyf

	inc e		; write next sector
	jp wrCFf
wrCFdonef:
	call UARTPage	; set page i/o reg to internal UART
	jp CMD

; Clear RAM disk directory starting from 0x80000 to 0x90000
; fill memory with 0xE5
; page 0xB is where this program resides
; page 1 is the window to access 16 meg memory space
ClearDir:
;	ld hl,clrdir$	; command message
;	call STROUT
	ld hl,confirm$	; confirm command execution
	call STROUT
	call tstCRLF
	jp nz,abort	; abort command if not CRLF
	call MMUPage
; initialize two system page descriptors, page 0xB and page 1
	ld a,1bh		; start with system page 0xB where this program is located
	out (MMUptr),a
	ld c,MMUsel	; points to MMU select reg
	ld hl,0bah	; system page 0xB descriptor logical=physical, enable cache, valid 
;	outw (c),hl	; write system page 0xB 
	db 0edh,0bfh	; op code for OUTW (C),HL
; 3/25/18 move RAMdisk directory to 0x80000
	ld hl,0808h	; system page 1 maps to 0x80000, disable cache, valid
	push hl		; will use this value later
	ld a,11h		; point to system page 1
	out (MMUptr),a	;
;	outw (c),hl	; write system page 1	
	db 0edh,0bfh	; op code for OUTW (C),HL
	ld c,MMUctrl	; point to MMU master control reg
	ld hl,03bffh	; enable system translate
;	outw (c),hl	; turn on MMU
	db 0edh,0bfh	; op code for OUTW (C),HL
	ld d,16		; reg d is loop counter, do this 16 times
	ld a,11h		; point to system page 1
	out (MMUptr),a
	ld c,MMUsel	; point to MMU select
clrDir1:
; 0x1000-0x1FFF maps to 0x080000-0x080FFF
	ld hl,1000h	; start with 0x080000
clrDir:
	ld a,0e5h		; fill directory area with 0xE5
	ld (hl),a
	inc hl
	ld a,20h		; hl reaches 0x2000?
	cp a,h
	jp nz,clrDir
	pop hl		; get the previous system page 1 descriptor value
	dec d		; decrement loop counter
	jp z,clrDir2
	ld a,10h		; increment to next 4K page
	add a,l		; go thru 16 4K page from 0x080000 to 0x08F000
	ld l,a
	push hl		; save the new descriptor value for next iteration
;	outw (c),hl	; write system page 1	
	db 0edh,0bfh	; op code for OUTW (C),HL
	jp clrDir1
clrDir2:
	ld c,MMUctrl	; point to MMU master control reg
	ld hl,33ffh	; turn off MMU, 
;	outw (c),hl	; turn off MMU
	db 0edh,0bfh	; op code for OUTW (C),HL
	nop		; OUTJMP bug fix
	nop
	nop
	nop
	call UARTPage	; restore Page I/O reg to default
	jp CMD
; print help message
HELP:
	ld hl,HELP$	; print help message
	call STROUT
	jp CMD
; boot CPM
; copy program from LA9-LA26 (9K) to 0xDC00
; jump to 0xF200 after copy is completed.
BootCPM:
	ld hl,bootcpm$	; print command message
	call STROUT
	call CIN		; get input
	cp '1'		; '1' is user apps
	jp z,bootApps
	cp '2'		; '2' is cpm2.2
	jp z,boot22
	cp '3'		; '3' is cpm3, not implemented
	jp z,boot3
	jp what
boot3:
	ld hl,confirm$	; CRLF to execute the command
	call STROUT
	call tstCRLF
	jp nz,abort	; abort command if no CRLF
	call CFPage	; initialize page i/o reg to CF
	ld a,40h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	ld hl,1100h	; CPM3LDR starts from 0x1100
	ld c,CFdata	; reg C points to CF data reg
	ld d,1h		; read from LA 1 to LA 0x0f, 7K--much bigger than needed
readCPM3:
	ld a,1		; read 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,d		; read CPM sector
	cp 10h		; between LA1 and LA0fh
	jp z,goCPM3	; done copying, execute CPM
	out (CF07),a	; 
	ld a,20h		; read sector command
	out (CFstat),a	; issue the read sector command
readdrq3:
	in a,(CFstat)	; check data request bit set before read CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jp z,readdrq3
	ld b,0h		; sector has 256 16-bit data
	db 0edh,92h	; op code for inirw input word and increment
;	inirw
	inc d		; read next sector
	jp readCPM3
goCPM3:
	call UARTPage	; set page i/o reg to internal UART
	jp 01100h		; BIOS starting address of CP/M

;	ld hl,notdone$	; boot to CPM 3 is not implemented
;	call STROUT
;	jp CMD
boot22:
	ld hl,confirm$	; CRLF to execute the command
	call STROUT
	call tstCRLF
	jp nz,abort	; abort command if no CRLF
;	call COUTdone	; wait for transmit done before switch page i/o reg
	call CFPage	; initialize page i/o reg to CF
	ld a,40h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	ld hl,0dc00h	; CPM starts from 0xDC00 to 0xFFFF
	ld c,CFdata	; reg C points to CF data reg
;	ld d,9		; read from LA 9 to LA27
	ld d,80h		; read from LA 0x80 to LA 0x92
readCPM1:
	ld a,1		; read 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,d		; read CPM sector
;	cp 27		; between LA9 and LA26
	cp 92h		; between LA80h and LA91h
	jp z,goCPM	; done copying, execute CPM
	out (CF07),a	; 
	ld a,20h		; read sector command
	out (CFstat),a	; issue the read sector command
readdrqCPM:
	in a,(CFstat)	; check data request bit set before read CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jp z,readdrqCPM
	ld b,0h		; sector has 256 16-bit data
	db 0edh,92h	; op code for inirw input word and increment
;	inirw
	inc d		; read next sector
	jp readCPM1
goCPM:
	call UARTPage	; set page i/o reg to internal UART
	jp 0f200h		; BIOS starting address of CP/M

bootApps:
; User applications resides in CF sector 0x40-0x7F.  
; Copy it to 0x0-0x7FFF and jump to 0x0
	ld hl,confirm$	; CRLF to execute the command
	call STROUT
	call tstCRLF
	jp nz,abort	; abort command if no CRLF
	call CFPage	; initialize page i/o reg to CF
	ld a,40h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	ld hl,0		; user apps starts from 0x0
	ld c,CFdata	; reg C points to CF data reg
	ld d,40h		; read from LA 0x40 to LA 0x7F
readApp1:
	ld a,1		; read 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,d		; read CPM sector
	cp 80h		; between LA40h and LA7fh
	jp z,goApps	; done copying, execute user apps
	out (CF07),a	; 
	ld a,20h		; read sector command
	out (CFstat),a	; issue the read sector command
readdrqApp:
	in a,(CFstat)	; check data request bit set before read CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jp z,readdrqApp
	ld b,0h		; sector has 256 16-bit data
	db 0edh,92h	; op code for inirw input word and increment
;	inirw
	inc d		; read next sector
	jp readApp1
goApps:
	call UARTPage	; set page i/o reg to internal UART
	jp 0h		; User apps starts at 0x0
; fill memory from end of program to 0xFFFF with zero or 0xFF
; also fill memory from 0x0 to 0xB000 with zero or 0xFF
fillZ:
	ld hl,fill0$	; print fill memory with 0 message
	call STROUT
	ld b,0		; fill memory with 0
	jp dofill
fillF:
	ld hl,fillf$	; print fill memory with F message
	call STROUT
	ld b,0ffh		; fill memory with ff
dofill:
	ld hl,confirm$	; get confirmation before executing
	call STROUT
	call tstCRLF	; check for carriage return
	jp nz,abort
	ld hl,PROGEND	; start from end of this program
	ld a,0ffh		; end address in reg A
filla:
	ld (hl),b		; write memory location
	inc hl
	cp h		; reached 0xFF00?
	jp nz,filla	; continue til done
	cp l		; reached 0xFFFF?
	jp nz,filla
	ld hl,0b000h	; fill value from 0xB000 down to 0x0000
fillb:
	dec hl
	ld (hl),b		; write memory location with desired value
	ld a,h		; do until h=l=0
	or l
	jp nz,fillb
	jp CMD
; Read CF
; Set page I/O to 0, afterward set it back to 0FEh
READCF:
	ld hl,read$	; put out read command message
	call STROUT
	ld hl,track$	; enter track in hex value
	call STROUT
	call GETHEX	; get a byte of hex value as track
	push af		; save track value in stack
	ld hl,sector$	; enter sector in hex value
	call STROUT
	call GETHEX	; get a byte of hex value as sector
	push af		; save sector value in stack
	call COUTdone	; wait for transmit done before switch page i/o reg
	call CFPage	; initialize page i/o reg to CF
;	push bc		; save register
;	push de
;	push hl
	ld hl,1000h	; copy previous block to 2000h
	ld de,2000h
	ld bc,200h	; copy 512 bytes
	ldir		; block copy
	ld a,40h		; set Logical Address addressing mode
	out (CF2427),a
	ld a,1		; read 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,0		; read first sector
	out (CF1623),a	; high byte of track is always 0
	pop af		; restore the sector value
	out (CF07),a	; write sector
	pop af		; restore the track value
	out (CF815),a
;	ld a,0		; LA sector 0
;	out (CF07),a	; 
	ld a,20h		; read sector command
	out (CFstat),a	; issue the read sector command
readdrq:
	in a,(CFstat)	; check data request bit set before read CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jp z,readdrq
	ld hl,1000h	; store CF data starting from 1000h
	ld c,CFdata	; reg C points to CF data reg
	ld b,0h		; sector has 256 16-bit data

	db 0edh,92h	; op code for inirw input word and increment
;	inirw
	ld hl,1000h	; compare with data block in 2000h
	ld bc,200h
	ld de,2000h
blkcmp:
	ld a,(de)		; get a byte from block in 2000h
	inc de
	cpi		; compare with corresponding data in 1000h
	jp po,blkcmp1	; exit at end of block compare
	jp z,blkcmp	; exit if data not compare
	call UARTPage
	ld hl,notsame$	; send out message that data not same as previous read
	call STROUT
	jp dumpdata
blkcmp1:
	call UARTPage	; initialize page i/o reg back to UART	
	ld hl,issame$	; send out message that data read is same as before
	call STROUT
dumpdata:
	ld d,32		; 32 lines of data
	ld hl,1000h	; display 512 bytes of data
dmpdata1:
	push hl		; save hl
	ld hl,CRLF$	; add a CRLF per line
	call STROUT
	pop hl		; hl is the next address to display
	call DMP16	; display 16 bytes per line
	dec d
	jp nz,dmpdata1
;;	dec hl		; point hl to the address that caused error
;;	ld a,'H'		; display content of HL reg
;;	call COUT		; print the HL label
;;	ld a,'L'
;;	call COUT
;;	call SPCOUT	
;;	call ADROUT	; output the content of HL 	
;	pop hl		; restore reg
;	pop de
;	pop bc	
	jp CMD

; Write CF
;  allowable parameters are '0' for boot sector & ZZMon, '1' for 32K apps, 
;   '2' for CPM2.2, '3' for CPM3
; Set page I/O to 0, afterward set it back to 0FEh
COPYCF:
	ld hl,copycf$	; print copy message
	call STROUT
	call CIN		; get write parameters
	cp '0'
	jp z,cpboot
	cp '1'
	jp z,cpAPPS
	cp '2'
	jp z,CopyCPM2
	cp '3'
	jp z,CopyCPM3
	jp what		; error, abort command

	jp CMD
; test for CR or LF.  Echo back. return 0
tstCRLF:
	call CIN		; get a character					
	cp 0dh		; if carriage return, output LF
	jp z,tstCRLF1
	cp 0ah		; if line feed, output CR 
	jp z,tstCRLF2
	ret
tstCRLF1:
	ld a,0ah		; put out a LF
	call COUT
	xor a		; set Z flag
	ret
tstCRLF2:
	ld a,0dh		; put out a CR
	call COUT
	xor a		; set Z flag
	ret

; write CPM to CF
; write data from 0xDC00 to 0xFFFF to CF LA128-LA146 (9K)
CopyCPM2:
;	call tstCRLF
;	jp nz,CMD	; abort command if not CR or LF
	ld hl,0dc00h	; CPM starts from 0xDC00 to 0xFFFF
	ld de,8092h	; reg DE contains beginning sector and end sector values
	jp wrCF
CopyCPM3:
	ld hl,1100h	; CPMLDR starts from 0x1100
	ld de,0110h	; reg DE contains beginning sector and end sector values
	jp wrCF
cpboot:
;	call tstCRLF
;	jp nz,CMD	; abort command if not CR or LF
	ld hl,confirm$	; carriage return to execute the program
	call STROUT
	call tstCRLF
	jp nz,CMD		; abort command if not CR or LF
	ld hl,0b200h	; cold boot loader is included in this program at org 0xB200
	call wrCFb
;;disable:
;;	jp wrCF		; this instruction will be zero-ed (NOP) when ZZMon is copied to CF
;;	ld hl,notavail$	; Do not allow boot sector to be changed 
;;	call STROUT
;;	jp CMD
;;cpZZMon:
;	call tstCRLF
;	jp nz,CMD
;;	ld hl,disable	; nop the "jp wrCF" instruction for copying boot sector
			; this is because CFMonLdr is not copied into CF
;;	ld (hl),0		; 0 is nop instruction
;;	inc hl
;;	ld (hl),0
;;	inc hl
;;	ld (hl),0
	ld hl,0b400h	; ZZMon starts from 0xB400 to 0xBFFF
	ld de,0f8feh	; last 8 sectors of track 0 reserved for ZZMon.  
	jp wrCF1		; CF is already initialized in wrCFb routine, jump directly
			; to sector copy routine
cpAPPS:
	ld hl,0		; Application starts from 0 to 0x7FFF
	ld de,407fh	; reg DE contains beginning sector and end sector values
	
wrCF:
	push hl		; save value
	ld hl,confirm$	; carriage return to execute the program
	call STROUT
	pop hl
	call tstCRLF
	jp nz,CMD	; abort command if not CR or LF
	call CFPage	; initialize page i/o reg to CF
	ld a,40h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	ld c,CFdata	; reg C points to CF data reg
wrCF1:
	ld a,1		; write 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,d		; write CPM sector
	cp e		; reg E contains end sector value
	jp z,wrCFdone	; done copying, execute CPM
	out (CF07),a	; 
	ld a,30h		; write sector command
	out (CFstat),a	; issue the write sector command
wrdrq:
	in a,(CFstat)	; check data request bit set before write CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jp z,wrdrq
	ld b,0h		; sector has 256 16-bit data

	db 0edh,93h	; op code for otirw output word and increment
;	otirw
readbsy:
; spin on CF status busy bit
	in a,(CFstat)	; read CF status 
	and 80h		; mask off all except busy bit
	jp nz,readbsy

	inc d		; write next sector
	jp wrCF1
wrCFdone:
	call UARTPage	; set page i/o reg to internal UART
	jp CMD
; This routine is dedicated to write boot sector of CF disk
wrCFb:
	call CFPage	; initialize page i/o reg to CF
	ld a,40h		; set LBA mode
	out (CF2427),a
	ld a,1		; write 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	out (CF07),a	; boot sector
	ld c,CFdata	; reg C points to CF data reg
	ld a,30h		; write sector command
	out (CFstat),a	; issue the write sector command
wrdrqb:
	in a,(CFstat)	; check data request bit set before write CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jp z,wrdrqb
	ld b,0h
	db 0edh,93h	; op code for otirw output word and increment
;	otirw
readbsyb:
; spin on CF status busy bit
	in a,(CFstat)	; read CF status 
	and 80h		; mask off all except busy bit
	jp nz,readbsyb
	ret




TESTRAM:
; test memory from top of this program to 0xFFFE 
	ld hl,testram$	; print test ram message
	call STROUT
	ld hl,confirm$	; get confirmation before executing
	call STROUT
	call tstCRLF	; check for carriage return
	jp nz,abort
	ld iy,(testseed)	; a prime number seed, another good prime number is 211
TRagain:
	ld hl,PROGEND	; start testing from the end of this program
	ld de,137		; increment by prime number
TRLOOP:
	push iy		; bounce off stack
	pop bc
	ld (hl),c		; write a pattern to memory
	inc hl
	ld (hl),b
	inc hl
	add iy,de		; add a prime number
	ld a,0ffh		; compare h to 0xff
	cp h
	jp nz,TRLOOP	; continue until reaching 0xFFFE
	ld a,0feh		; compare l to 0xFE
	cp l
	jp nz,TRLOOP
	ld hl,0b000h	; test memory from 0xAFFF down to 0x0000
TR1LOOP:
	push iy
	pop bc		; bounce off stack
	dec hl
	ld (hl),b		; write MSB
	dec hl
	ld (hl),c		; write LSB
	add iy,de		; add a prime number
	ld a,h		; check h=l=0
	or l
	jp nz,TR1LOOP
	ld hl,PROGEND	; verify starting from the end of this program
	ld iy,(testseed)	; starting seed value
TRVER:
	push iy		; bounce off stack
	pop bc
	ld a,(hl)		; get LSB
	cp c		; verify
	jp nz,TRERROR
	inc hl
	ld a,(hl)		; get MSB
	cp b
	jp nz,TRERROR
	inc hl
	add iy,de		; next reference value
	ld a,0ffh		; compare h to 0xff
	cp h
	jp nz,TRVER	; continue verifying til end of memory
	ld a,0feh		; compare l to 0xFE
	cp l
	jp nz,TRVER
	ld hl,0b000h	; verify memory from 0xB000 down to 0x0000
TR1VER:
	push iy		; bounce off stack
	pop bc
	dec hl
	ld a,(hl)		; get MSB from memory
	cp b		; verify
	jp nz,TRERROR
	dec hl
	ld a,(hl)		; get LSB from memory
	cp c
	jp nz,TRERROR
	add iy,de
	ld a,h		; check h=l=0
	or l
	jp nz,TR1VER
	call SPCOUT	; a space delimiter
	ld a,'O'		; put out 'OK' message
	call COUT
	ld a,'K'
	call COUT
	ld (testseed),iy	; save seed value

	IN A,(RxStat)	; read on-chip UART receive status
        	AND 10H				;;Z data available?
        	JP Z,TRagain	; no char, do another iteration of memory test
        	IN A,(RxData)	; save to reg A
        	OUT (TxData),A	; echo back
;	cp 'X'		; if 'X' or 'x', exit memory test
;	jp z,CMD
;	cp 'x'
;	jp nz,TRagain
	jp CMD
TRERROR:
	call SPCOUT	; a space char to separate the 'r' command
	ld a,'H'		; display content of HL reg
	call COUT		; print the HL label
	ld a,'L'
	call COUT
	call SPCOUT	
	call ADROUT	; output the content of HL 	
	jp CMD

;Get an address and jump to it
go:
	ld hl,go$		; print go command message
	call STROUT
        	CALL ADRIN
        	LD H,D
        	LD L,E
	push hl		; save go address
	ld hl,confirm$	; get confirmation before executing
	call STROUT
	call tstCRLF	; check for carriage return
	pop hl
	jp nz,abort
;	ld hl,CRLF$	; insert CRLF before executing
;	call STROUT
;	pop hl		; restore saved go address
	jp (hl)		; jump to address if CRLF

;;;;;;;;;;;;;;;;;;;;;;;;;;; Utilities from Glitch Works ver 0.1 ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; Copyright (C) 2012 Jonathan Chapman ;;;;;;;;;;;;;;;;;;

;Edit memory from a starting address until X is
;pressed. Display mem loc, contents, and results
;of write.
EDMEM:  	CALL SPCOUT
        	CALL ADRIN
        	LD H,D
        	LD L,E
ED1:    	LD A,13
        	CALL COUT
        	LD A,10
        	CALL COUT
        	CALL ADROUT
        	CALL SPCOUT
        	LD A,':'
        	CALL COUT
        	CALL SPCOUT
        	CALL DMPLOC
        	CALL SPCOUT
        	CALL GETHEX
        	JP C,CMD
        	LD (HL),A
        	CALL SPCOUT
        	CALL DMPLOC
        	INC HL
        	JP ED1

;Dump memory between two address locations
MEMDMP: 	CALL SPCOUT
        	CALL ADRIN
        	LD H,D
        	LD L,E
        	LD C,10h
        	CALL SPCOUT
        	CALL ADRIN
MD1:    	LD A,13
        	CALL COUT
        	LD A,10
        	CALL COUT
        	CALL DMP16
        	LD A,D
        	CP H
        	JP M,CMD
        	LD A,E
        	CP L
        	JP M,MD2
        	JP MD1
MD2:    	LD A,D
        	CP H
        	JP NZ,MD1
        	JP CMD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DMP16 -- Dump 16 consecutive memory locations
;
;pre: HL pair contains starting memory address
;post: memory from HL to HL + 16 printed
;post: HL incremented to HL + 16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DMP16:  	CALL ADROUT
        	CALL SPCOUT
        	LD A,':'
        	CALL COUT
        	LD C,10h
DM1:    	CALL SPCOUT
        	CALL DMPLOC
        	INC HL		
        	DEC C
        	RET Z
        	JP DM1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DMPLOC -- Print a byte at HL to console
;
;pre: HL pair contains address of byte
;post: byte at HL printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DMPLOC: 	LD A,(HL)
        	CALL HEXOUT
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HEXOUT -- Output byte to console as hex
;
;pre: A register contains byte to be output
;post: byte is output to console as hex
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEXOUT: 	PUSH BC
        	LD B,A
        	RRCA
        	RRCA
        	RRCA
        	RRCA
        	AND 0Fh
        	CALL HEXASC
        	CALL COUT
        	LD A,B
        	AND 0Fh
        	CALL HEXASC
        	CALL COUT
        	POP BC
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HEXASC -- Convert nybble to ASCII char
;
;pre: A register contains nybble
;post: A register contains ASCII char
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEXASC: 	ADD 90h
        	DAA
        	ADC A,40h
        	DAA
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ADROUT -- Print an address to the console
;
;pre: HL pair contains address to print
;post: HL printed to console as hex
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ADROUT: 	LD A,H
        	CALL HEXOUT
        	LD A,L
        	CALL HEXOUT
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ADRIN -- Get an address word from console
;
;pre: none
;post: DE contains address from console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ADRIN:  	CALL GETHEX
        	LD D,A
        	CALL GETHEX
        	LD E,A
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GETHEX -- Get byte from console as hex
;
;pre: none
;post: A register contains byte from hex input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GETHEX: 	PUSH DE
        	CALL CIN
        	CP 'X'
        	JP Z,GE2
	cp 'x'		; exit with lower 'x'
	jp z,GE2
        	CALL ASCHEX
        	RLCA
        	RLCA
        	RLCA
        	RLCA
        	LD D,A
        	CALL CIN
        	CALL ASCHEX
        	OR D
GE1:    	POP DE
        	RET
GE2:    	SCF
        	JP GE1

; get hex without echo back
GETHEXQ:
	push de		; save register 
        	CALL CINQ
        	CALL ASCHEX
        	RLCA
        	RLCA
        	RLCA
        	RLCA
        	LD D,A
        	CALL CINQ
        	CALL ASCHEX
        	OR D 
  	pop de			;restore register
        	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ASCHEX -- Convert ASCII coded hex to nybble
;
;pre: A register contains ASCII coded nybble
;post: A register contains nybble
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ASCHEX: 	SUB 30h
        	CP 0Ah
        	RET M
        	AND 5Fh
        	SUB 07h
        	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GOBYT -- Push a two-byte instruction and RET
;         and jump to it
;
;pre: B register contains operand
;pre: C register contains opcode
;post: code executed, returns to caller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GOBYT:  	LD HL,0000
        	ADD HL,SP
        	DEC HL
        	LD (HL),0C9h
        	DEC HL
        	LD (HL),B
        	DEC HL
        	LD (HL),C
        	JP (HL)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SPCOUT -- Print a space to the console
;
;pre: none
;post: 0x20 printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPCOUT: 	LD A,' '
        	CALL COUT
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;STROUT -- Print a null-terminated string
;
;pre: HL contains pointer to start of a null-
;     terminated string
;post: string at HL printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STROUT: 	LD A,(HL)
        	CP 00
        	RET Z
        	CALL COUT
        	INC HL
        	JP STROUT
;;;;;;;;;;;;;;;;;;;;;;;;;;; Utilities by Glitch Works ver 0.1 ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; Copyright (C) 2012 Jonathan Chapman ;;;;;;;;;;;;;;;;;;

; init page i/o reg to point to UART
UARTPage:
	push bc		; save register
	push hl
	ld c,08h		; reg c points to I/O page register
	ld l,0feh		; set I/O page register to 0xFE
	db 0edh,6eh	; this is the op code for LDCTL (C),HL
;	ldctl (c),hl	; write to I/O page register
;	ld a,0e2h		; initialize the UART configuration register
;	out (UARTconf),a
;	ld a,80h		;enable UART transmit and receive
;	out (TxStat),a
;	out (RxStat),a
	pop hl		; restore reg
	pop bc
	ret
; initialize Z280 page i/o reg to point to MMU and DMA
DMAPage:
MMUPage:
	push bc		; save reg
	push hl
	ld c,8		; reg C points to I/O page reg
	ld l,0ffh		; MMU page I/O reg is 0xFF
	db 0edh,6eh	; op code for LDCTL (C),HL
	pop hl
	pop bc		; restore reg
	ret

; init page i/o reg to point to compactflash
CFPage:
	push bc		; save register
	push hl
	ld c,08h		; reg c points to I/O page register
	ld l,0		; set I/O page register to 0
	db 0edh,6eh	; this is the op code for LDCTL (C),HL
;	ldctl (c),hl	; write to I/O page register
	pop hl		; restore reg
	pop bc
	ret

RxData  	equ 16h        	; on-chip UART receive register
TxData  	equ 18h        	; on-chip UART transmit register
RxStat  	equ 14h        	; on-chip UART transmitter status/control register
TxStat  	equ 12h        	; 0n-chip UART receiver status/control register

;Get a char from the console and echo
CIN:    
        	IN A,(RxStat)	; read on-chip UART receive status
        	AND 10H				;;Z data available?
        	JP Z,CIN
        	IN A,(RxData)	; save to reg A
        	OUT (TxData),A	; echo back
        	RET
; get char from console without echo
CINQ:
        	IN A,(RxStat)	; read on-chip UART receive status
        	AND 10H				;;Z data available?
        	JP Z,CINQ
        	IN A,(RxData)	; save to reg A
        	RET

;Output a character to the console
COUT:   

;	EX AF,AF'		; save data to be printed to alternate bank
	push af		; save data to be printed to stack
COUT1:  	IN A,(TxStat)	; transmit empty?
        	AND 01H
        	JP Z,COUT1
	pop af		; restore data to be printed
;	EX AF,AF'		; restore data to be printed
        	OUT (TxData),A	; write it out
        	RET

; check UART output completed
COUTdone:
	in a,(TxStat)	; trasmit empty?
	and 1
	jp z,COUTdone	; wait until transmit empty
	ret
;PROGEND:	equ $		; end of the program
PROGEND:	equ 0c000h		; end of the program is above the stack

signon$:	db "TinyZZ Monitor v0.99 6/9/18", 13,10,0
;        	db "Format drives command",13,10,0 
PROMPT$:	db 13, 10, 10, ">", 0
what$:   	db 13, 10, "?", 0
CRLF$	db 13,10,0
confirm$	db " press Return to execute command",0
abort$	db 13,10,"command aborted",0
notdone$	db 13,10,"command not implemented",0
go$	db "o to address: 0x",0
track$	db " track:0x",0
sector$	db " sector:0x",0
read$	db "ead CF",0
notsame$	db " data not same as previous read",10,13,0
issame$	db " data same as previous read",10,13,0
fillf$	db "ill memory with 0xFF",10,13,0
fill0$	db "ero memory",10,13,0
testram$	db "est memory",10,13,0
copycf$	db "opy to CF",10,13
	db "0--boot,",10,13
	db "1--User Apps,",10,13
	db "2--CP/M2.2,",10,13
	db "3--CP/M3: ",0
clrdir$	db " clear disk directories",10,13
	db "A -- drive A,",10,13
	db "B -- drive B,",10,13
	db "C -- drive C,",10,13
	db "D -- drive D,",10,13	
	db "E -- RAM drive: ",0
bootcpm$	db "oot CP/M",10,13
	db "1--User Apps,",10,13
	db "2--CP/M2.2,",10,13
	db "3--CP/M3: ",0
notavail$	db 13,10,"boot sector not changable in this mode",0
HELP$	db "elp",13,10
	db "G <addr> CR",13,10
	db "R <track> <sector>",13,10
	db "D <start addr> <end addr>",13,10
	db "Z CR",13,10
	db "F CR",13,10
	db "T CR",13,10
	db "E <addr>",13,10
	db "X <options> CR",13,10
	db "B <options> CR",13,10
	db "C <options> CR",0
; place help message at the end.  In case stac overflow, it'll trash help message

	org 0B200h
; This is the cold bootstrap the load the CF copying program to 0xC000 and run

	ld hl,0c000h	; create CFMon in 0xC000
          ld (hl),3eh	; op code for LD A,40h
	inc hl
	ld (hl),40h
	inc hl
          ld (hl),0d3h	; op code for OUT (CF2427),A
	inc hl
          ld (hl),0cdh
	inc hl
          ld (hl),16h	; op code for LD D,0F8h
	inc hl
	ld (hl),0f8h
	inc hl
          ld (hl),21h	; op code for LD HL,0B400h
	inc hl
	ld (hl),0h
	inc hl
	ld (hl),0B4h
	inc hl
          ld (hl),0eh	;op code for LD C,CFdata
	inc hl
	ld (hl),0c0h
	inc hl
          ld (hl),3eh	;op code for LD A,1
	inc hl
	ld (hl),1h
	inc hl	
          ld (hl),0d3h	;op code for OUT (CFsectcnt),A
	inc hl
	ld (hl),0c5h	
	inc hl	
          ld (hl),7ah	;op code for LD A,D
	inc hl
	ld (hl),0feh	;op code for CP 0FEh
	inc hl	
          ld (hl),0feh	
	inc hl
	ld (hl),0cah	;op code for JP Z,0B400h
	inc hl
          ld (hl),0h
	inc hl
	ld (hl),0b4h	
	inc hl
          ld (hl),0d3h	;op code for OUT (CF07),A
	inc hl
	ld (hl),0c7h
	inc hl
          ld (hl),3eh	;op code for LD A,20h
	inc hl
	ld (hl),20h
	inc hl	
          ld (hl),0d3h	;op code for OUT (CFstat),A
	inc hl
	ld (hl),0cfh
	inc hl
	ld (hl),0dbh	;op code for IN A,(CFstat)
	inc hl
	ld (hl),0cfh	
	inc hl
	ld (hl),0e6h	;op code for AND 80h
	inc hl
	ld (hl),80h
	inc hl
	ld (hl),0c2h	;op code for JP NZ,0C01bh
	inc hl
	ld (hl),1bh
	inc hl
	ld (hl),0c0h
	inc hl
	ld (hl),0dbh	;op code for IN A,(CFstat)
	inc hl
	ld (hl),0cfh
	inc hl
          ld (hl),0e6h	;op code for AND 8
	inc hl
	ld (hl),8h
	inc hl		
          ld (hl),0cah	;op code for JP Z,0C022h
	inc hl
	ld (hl),22h
	inc hl
          ld (hl),0c0h
	inc hl
	ld (hl),6h	;op code for LD B,0h
	inc hl
          ld (hl),0h
	inc hl
	ld (hl),0edh	;op code for INIRW
	inc hl
          ld (hl),92h
	inc hl
	ld (hl),0dbh	;op code for IN A,(CFstat)
	inc hl	
          ld (hl),0cfh
	inc hl
	ld (hl),14h	;op code for INC D
	inc hl	
          ld (hl),0c3h	;op code for JP 0C00bh
	inc hl
	ld (hl),0bh
	inc hl		
          ld (hl),0c0h

	jp 0c000h		; start CFMon execution at 0xC000
	END
; This is the CFMon program that'll be created in 0xC000 by the CFMonLdr
                             A       23 	org 0C000h
0000C000 3E 40               A       25 	ld a,40h		; LA addressing mode
0000C002 D3 CD               A       26 	out (CF2427),a
0000C004 16 F8               A       27 	ld d,0f8h		; points to sector to read, last 8 sectors in track 0
0000C006 21 00 B4            A       28 	ld hl,0b400h	; store CF data starting from 0b400h
0000C009 0E C0               A       29 	ld c,CFdata	; reg C points to CF data reg
0000C00B                     A       30 moresect:
0000C00B 3E 01               A       31 	ld a,1		; read 1 sector
0000C00D D3 C5               A       32 	out (CFsectcnt),a	; write to sector count with 1
0000C00F 7A                  A       33 	ld a,d		; read sector pointed by reg D
0000C010 FE FE               A       34 	cp 0feh		; read sectors 0xF8-0xFD
0000C012 CA 00 B4            A       35 	jp z,0b400h		; load completed, run program loaded at 0xB400
0000C015 D3 C7               A       36 	out (CF07),a	; read the sector pointed by reg D		
0000C017 3E 20               A       41 	ld a,20h		; read sector command
0000C019 D3 CF               A       42 	out (CFstat),a	; issue the read sector command
0000C01B                     A       43 readbsy:
0000C01B DB CF               A       44 	in a,(CFstat)	; check bsy flag first
0000C01D E6 80               A       45 	and 80h		; bsy flag is at bit 7
0000C01F C2 1B C0            A       46 	jp nz,readbsy
0000C022                     A       47 readdrq:
0000C022 DB CF               A       48 	in a,(CFstat)	; check data request bit set before read CF data
0000C024 E6 08               A       49 	and 8		; bit 3 is DRQ, wait for it to set
0000C026 CA 22 C0            A       50 	jp z,readdrq
                             A       51 
0000C029 06 00               A       52 	ld b,0h		; sector has 256 16-bit data
0000C02B ED 92               A       53 	db 0edh,92h	; op code for inirw input word and increment
                             A       54 ;	inirw		; reg HL and c are already setup at the top
0000C02D DB CF               A       55 	in a,(CFstat)	; OUTJMP bug fix
0000C02F 14                  A       56 	inc d
0000C030 C3 0B C0            A       57 	jp moresect
	

