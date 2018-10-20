# Creating a new CF disk for Z280RC with ZZMon ver 0.99
## Introduction

This page describes the steps for creating a new CF disk for Z280RC. The process has been tested successfully for several brands of CF and for size from 64meg to 4G. TeraTerm is the terminal program, but the procedure should work for terminal programs that can send binary & ASCIIfiles. The response of Z280RC is in `code section`. The software version of ZZMon is 0.99.
## Load ZZMon in UART Bootstrap mode

Enable the UART Bootstrap mode by removing the Mode jumper.
Send '[loadngo.run](./SystemSoftware/loadngo.run) ' as binary file: ← **Please note: it may be necessary to add 1ms transmission delay to every line**
```
……………………………………………………………………………………………………………………………………………UX
TinyZZ Monitor v0.99 6/9/18

>help
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

>copy to CF
0–boot,
1–User Apps,
2–CP/M2.2,
3–CP/M3: 0 press Return to execute command
```
### Install CFMon and ZZMon

With 'c0' command, CFMon & ZZMon is copied to the CF disk. This concludes the loading of bootstrap software in UART bootstrap mode. The remainder of the instruction is carried out with the Mode jumper installed and Z280RC operates in CF bootstrap mode.
## Load files in CF Bootstrap mode

Enable the CF bootstrap mode and reset. It is not necessary to add line transmission delay to the serial port communication in the following.
### Install CP/M2.2

Load [cpm22all.hex](./SystemSoftware/cpm22all.hex) before issuing 'c2' command.
```
TinyZZ Monitor v0.99 6/9/18

>………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………………….UX

>

>copy to CF
0–boot,
1–User Apps,
2–CP/M2.2,
3–CP/M3: 2 press Return to execute command
```
### Install CP/M 3

Load cpmldr.hex before issuing 'c3' command.
```
>…………………………………………………………………………………………………………X

>

>copy to CF
0–boot,
1–ZZMon,
2–CP/M2.2,
3–CP/M3: 3 press Return to execute command
```
### Install CP/M22 distribution files

Clear drives A/B/C/D before loading CPM distribution files
```
>x clear disk directories
A – drive A,
B – drive B,
C – drive C,
D – drive D,
E – RAM drive: A press Return to execute command

>x clear disk directories
A – drive A,
B – drive B,
C – drive C,
D – drive D,
E – RAM drive: B press Return to execute command

>x clear disk directories
A – drive A,
B – drive B,
C – drive C,
D – drive D,
E – RAM drive: C press Return to execute command

>x clear disk directories
A – drive A,
B – drive B,
C – drive C,
D – drive D,
E – RAM drive: D press Return to execute command
```
load cpm22dri.hex, this is the cpm22 distribution files.
```
>E………………………………………………………………long response, truncated……………………………………………..X

>
```
The distribution files are now in drive E. Boot CPM22 and copy files from drive E to drive B.
```
>boot CP/M
1–User Apps,
2–CP/M2.2,
3–CP/M3: 2 press Return to execute command
Copyright 1979 © by Digital Research
CP/M 2.2 for TinyZ280
3/25/18 3.5 meg RAMDisk

a>e:
e>dir
E: ASM COM : BIOS ASM : CBIOS ASM : DDT COM
E: DEBLOCK ASM : DISKDEF LIB : DUMP COM : DUMP ASM
E: ED COM : LOAD COM : MOVCPM COM : PIP COM
E: STAT COM : SUBMIT COM : SYSGEN COM : XSUB COM
e>pip b:=*.*[v]

COPYING -
ASM.COM
BIOS.ASM
CBIOS.ASM
DDT.COM
DEBLOCK.ASM
DISKDEF.LIB
DUMP.COM
DUMP.ASM
ED.COM
LOAD.COM
MOVCPM.COM
PIP.COM
STAT.COM
SUBMIT.COM
SYSGEN.COM
XSUB.COM
```
CPM22 distribution files are now successfully copied to drive B.
### Install CP/M 3 distribution files

Load the CPM3 distribution files, CPM3DSTR.HEX
It is a big file, taking 2 minutes and 20 seconds to load at 115200 buad.
```
e>TinyZZ Monitor v0.99 6/9/18

>E………………………………………………………………long response, truncated……………………………………………..X
```
The distribution files are in drive E. Boot with CPM22 and copy drive E to drive A.
```
>boot CP/M
1–User Apps,
2–CP/M2.2,
3–CP/M3: 2 press Return to execute command
Copyright 1979 © by Digital Research
CP/M 2.2 for TinyZ280
3/25/18 3.5 meg RAMDisk

a>b:

b>dir e:
E: BDOS3 SPR : BIOS3 SPR : BIOSKRNL ASM : BNKBDOS3 SPR
E: BOOT ASM : CALLVERS ASM : CBIOS3 REL : CCP COM
E: CHARIO ASM : COPYSYS ASM : COPYSYS COM : CPM3 LIB
E: CPM3 SYS : CPMLDR REL : DATE COM : DEVICE COM
E: DIR COM : DIRLBL RSX : DRVTBL ASM : DUMP ASM
E: DUMP COM : ECHOVERS ASM : ED COM : ERASE COM
E: FD1797SD ASM : GENCOM COM : GENCPM COM : GET COM
E: HELP COM : HELP HLP : HEXCOM COM : HIST UTL
E: INITDIR COM : LDRBIOS REL : LIB COM : LINK COM
E: MAC COM : MODEBAUD LIB : MOVE ASM : PATCH COM
E: PIP COM : PORTS LIB : PUT COM : RANDOM ASM
E: RENAME COM : RESBDOS3 SPR : RMAC COM : SAVE COM
E: SCB REL : SET COM : SETDEF COM : SHOW COM
E: SID COM : SUBMIT COM : TRACE UTL : TYPE COM
E: XMODEM COM : XREF COM
b>pip a:=e:*.*[v]

COPYING -
BDOS3.SPR
BIOS3.SPR
BIOSKRNL.ASM
BNKBDOS3.SPR
BOOT.ASM
CALLVERS.ASM
CBIOS3.REL
CCP.COM
CHARIO.ASM
COPYSYS.ASM
COPYSYS.COM
CPM3.LIB
CPM3.SYS
CPMLDR.REL
DATE.COM
DEVICE.COM
DIR.COM
DIRLBL.RSX
DRVTBL.ASM
DUMP.ASM
DUMP.COM
ECHOVERS.ASM
ED.COM
ERASE.COM
FD1797SD.ASM
GENCOM.COM
GENCPM.COM
GET.COM
HELP.COM
HELP.HLP
HEXCOM.COM
HIST.UTL
INITDIR.COM
LDRBIOS.REL
LIB.COM
LINK.COM
MAC.COM
MODEBAUD.LIB
MOVE.ASM
PATCH.COM
PIP.COM
PORTS.LIB
PUT.COM
RANDOM.ASM
RENAME.COM
RESBDOS3.SPR
RMAC.COM
SAVE.COM
SCB.REL
SET.COM
SETDEF.COM
SHOW.COM
SID.COM
SUBMIT.COM
TRACE.UTL
TYPE.COM
XMODEM.COM
XREF.COM
```
CPM3 is now in drive A.
The disk is now bootable with CPM3
```
>TinyZZ Monitor v0.99 6/9/18

>boot CP/M
1–User Apps,
2–CP/M2.2,
3–CP/M3: 3 press Return to execute command

Boot LDRBIOS

CP/M V3.0 Loader
Copyright (C) 1998, Caldera Inc.

BIOS3 SPR E800 1000
BDOS3 SPR C900 1F00

50K TPA
Copyright 1979 © by Digital Research
CP/M 3 for TinyZ280 3/25/18 3.5meg RAMdisk
A>dir
A: BDOS3 SPR : BIOS3 SPR : BIOSKRNL ASM : BNKBDOS3 SPR : BOOT ASM
A: CALLVERS ASM : CBIOS3 REL : CCP COM : CHARIO ASM : COPYSYS ASM
A: COPYSYS COM : CPM3 LIB : CPM3 SYS : CPMLDR REL : DATE COM
A: DEVICE COM : DIR COM : DIRLBL RSX : DRVTBL ASM : DUMP ASM
A: DUMP COM : ECHOVERS ASM : ED COM : ERASE COM : FD1797SD ASM
A: GENCOM COM : GENCPM COM : GET COM : HELP COM : HELP HLP
A: HEXCOM COM : HIST UTL : INITDIR COM : LDRBIOS REL : LIB COM
A: LINK COM : MAC COM : MODEBAUD LIB : MOVE ASM : PATCH COM
A: PIP COM : PORTS LIB : PUT COM : RANDOM ASM : RENAME COM
A: RESBDOS3 SPR : RMAC COM : SAVE COM : SCB REL : SET COM
A: SETDEF COM : SHOW COM : SID COM : SUBMIT COM : TRACE UTL
A: TYPE COM : XMODEM COM : XREF COM
```
Install optional game files

load the Zork123 games to drive E and copy to drive D.
It is also a big file taking 4 minutes 30 seconds to load.
```
A>TinyZZ Monitor v0.99 6/9/18

>E………………………………………………………………long response, truncated……………………………………………..X

>boot CP/M
1–User Apps,
2–CP/M2.2,
3–CP/M3: 2 press Return to execute command
Copyright 1979 © by Digital Research
CP/M 2.2 for TinyZ280
3/25/18 3.5 meg RAMDisk

a>dir e:
E: ZORK123 PKG
a>b:
b>pip d:=e:*.pkg

COPYING -
ZORK123.PKG
```
Upload depkg.com via xmodem to decompress zork123.pkg
```
b>dir
B: ASM COM : BIOS ASM : CBIOS ASM : DDT COM
B: DEBLOCK ASM : DISKDEF LIB : DUMP COM : DUMP ASM
B: ED COM : LOAD COM : MOVCPM COM : PIP COM
B: STAT COM : SUBMIT COM : SYSGEN COM : XSUB COM
b>a:xmodem depkg.com /r/c/x0

File created
Receiving via CON with checksums
OK
Received 80 blocks
b>pip d:=depka g.com

b>d:
d>dir
D: ZORK123 PKG : DEPKG COM
d>depkg zork123.pkg
– Reading ZORK123.PKG
Extracting ZORK3.COM
……………………………..
…………………………….

Extracting ZORK3.DAT
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………….

Extracting ZORK1.COM
……………………………..
…………………………….

Extracting ZORK1.DAT
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..

Extracting ZORK2.COM
……………………………..
…………………………….

Extracting ZORK2.DAT
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
……………………………..
…..

– Done.

d>dir
D: ZORK123 PKG : DEPKG COM : ZORK3 COM : ZORK3 DAT
D: ZORK1 COM : ZORK1 DAT : ZORK2 COM : ZORK2 DAT
d>era zork123.pkg
d>zork1
ZORK I: The Great Underground Empire
Copyright © 1981, 1982, 1983 Infocom, Inc. All rights
reserved.
ZORK is a registered trademark of Infocom, Inc.
Revision 88 / Serial number 840726

West of House
You are standing in an open field west of a white house, with
a boarded front door.
There is a small mailbox here.

>quit
Your score is 0 (total of 350 points), in 0 moves.
This gives you the rank of Beginner.
Do you wish to leave the game? (Y is affirmative): >y
```
