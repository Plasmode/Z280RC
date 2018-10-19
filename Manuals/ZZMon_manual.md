# ZZMon (Z280RC Monitor) V0.99 Manual

June 2018, reformatted for GitHub Oct 2018
## Introduction


ZZMon is the monitor program for Z280RC. In normal mode of operation it is stored in track 0 sector 0xF8-0xFF of the compact flash card. When power is initially applied, the cold bootstrap code which is stored in the bootsector of the compact flash card will copy the ZZMon from its location in CF to memory (0xB200-0xBFFF) and transfer control to ZZMon. When a new CF disk is first installed in the Z280RC, remove the boot mode jumper will enable the UART Bootstrap where ZZMon can be loaded serially at 115200 baud, odd parity, 1 stop bit and no handshakes. When loaded serially this way, ZZMon can initialize the new CF disk with cold bootstrap code in the bootsector and copy ZZMon into track 0, sector 0xF8-0xFF. With boot mode jumper installed, the initialized CF can operate in the normal mode.
## ZZMon commands


ZZMon is a simple monitor with the following single-key commands. Except when noted, the commands may be entered in upper or lower cases. In the following description, command entered is in **bold**, the response is in `code section`

**H**
```
help
G <addr> CR
R <track> <sector>
D <start addr> <end addr>
Z CR
F CR
T CR
E <addr>
X <options> CR
B <options> CR
C <options> CR
```
**G**

`go to address: 0x`

Enter the 4 hexadecimal address values. Confirm the command execution with a carriage return or abort the command with other keystroke.

**R**
`read CF track:0x`

Enter the 2 hexadecimal digits for the track number and 2 hex digits for the sector value. The content of the selected track/sector will be displayed as 512-byte data block.

```
read CF track:0x00 sector:0x00 data not same as previous read

1000 : 21 00 10 36 3E 23 36 40 23 36 D3 23 36 CD 23 36

1010 : 16 23 36 F8 23 36 21 23 36 00 23 36 04 23 36 0E
1020 : 23 36 C0 23 36 3E 23 36 01 23 36 D3 23 36 C5 23
1030 : 36 7A 23 36 FE 23 36 FE 23 36 CA 23 36 00 23 36
1040 : 04 23 36 D3 23 36 C7 23 36 3E 23 36 20 23 36 D3
1050 : 23 36 CF 23 36 DB 23 36 CF 23 36 E6 23 36 08 23
1060 : 36 CA 23 36 1B 23 36 10 23 36 06 23 36 00 23 36
1070 : ED 23 36 92 23 36 DB 23 36 CF 23 36 14 23 36 C3
1080 : 23 36 0B 23 36 10 C3 00 10 00 00 00 00 00 00 00
1090 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
10A0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
10B0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
10C0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
10D0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
10E0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
10F0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1100 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1110 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1120 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1130 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1140 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1150 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1160 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1170 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1180 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
1190 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
11A0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
11B0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
11C0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
11D0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
11E0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
11F0 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```
The address field in the first column is that of the buffer where sector data is stored.

**D**
display memory from 4 hexadecimal digits start address to 4 hexadecimal end address. If start address is greater than the end address, only 1 line (16 bytes) of data will be displayed.
```
D 0400 0420

0400 : C3 09 04 88 B0 FB 00 00 00 31 FF 0F 0E 08 2E FF
0410 : ED 6E DB E8 32 03 04 3E B0 D3 E8 DB E8 32 04 04
0420 : 2E 00 ED 6E D3 A0 CD 54 0A 3E E2 D3 10 3E 80 D3
```
**Z**
```
zero memory
press Return to execute command
```
Fill memory from 0xC000 to 0xFFFE and from 0x0 to 0xAFFF with 0x0. Press carriage return to confirm the command execution; press other key to abort the command

**F**
`fill memory with 0xFF`
press Return to execute command

Fill memory from 0xC000 to 0xFFFE and from 0x0 to 0xAFFF with 0xFF. Press carriage return to confirm the command execution; press other key to abort the command

T
test memory
press Return to execute command

Test memory from 0xC000 to 0xFFFE and from 0x0 to 0xAFFF. The memory is filled with unique test patterns generated from a seed value. The seed value is changed for each iteration of the test. Each completed iteration will display an 'OK' message. Any keystroke during the test with abort the test and return to command prompt.

E
Edit memory specified with the 4 hexadecimal digits value. Exit the edit session with 'X'

E 0000

0000 : FF 12 12
0001 : FF 23 23
0002 : EF 00 00
0003 : 7F 01 01
0004 : F7 x

X
clear disk directories
A – drive A,
B – drive B,
C – drive C,
D – drive D,
E – RAM drive:

Fill the directories of the selected disk with 0xE5. This effectively erase the entire disk. The disk letter __mustu be in upper case. Confirm the command with a carriage return or abort command with any other key stroke.

B
boot CP/M
1–User Apps,
2–CP/M2.2,
3–CP/M3:

Enter '1' to copy user applications program from CF disk to memory 0x0-0x7FFF and transfer control to 0x0. Enter '2' to boot CP/M 2.2 or enter '3' to boot CP/M3. This assumes the appropriate software has been copied to track 0 of CF as described under the “C” command. Confirm the command with a carriage return or abort command with any other key stroke.

boot CP/M
1–User Apps,
2–CP/M2.2,
3–CP/M3: 2 press Return to execute command
Copyright 1979 © by Digital Research
CP/M 2.2 for TinyZ280
3/7/18 DMA2&3 for RAMDisk

a>

C
copy to CF
0–boot,
1–User Apps,
2–CP/M2.2,
3–CP/M3:

Prior to execution of the C1 command, user application program must be loaded in memory from 0x0 up to 0x7FFF

Prior to execution of the C2 command, CP/M2.2 BDOS/CCP/BIOS must be loaded in memory 0xDC00-0xFFFF.

Prior to execution of the C3 command, CP/M3 CPMLDR must be loaded in memory starting from 0x1100.

Location of programs on CF track 0 (sector values are LBA):

CFMonLdr: boot sector (sector 0). CFMon is loaded to memory 0xC000

ZZMon: sector 0xF8-0xFF

CPM22ALL: sector 0x80-0x92

CPMLDR: sector 0x1-0xF
