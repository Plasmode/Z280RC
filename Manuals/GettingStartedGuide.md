# Getting Started with Z280RC

This is a quick start guide to get Z280RC power up and running.

![](https://github.com/Plasmode/Z280RC/blob/master/Manuals/Z280RC_connector_pic.jpeg)
## Setup Hardware

Refer to picture above for location of various hardware features.

* Z280RC needs a 5V power supply with maximum current of 400mA.
* A TTL-level serial adapter with Transmit and Receive and ground signals. No handshake signals are required. The terminal program parameters are: 115200 baud, Odd parity, 8 data bit, 1 stop and no handshake.
* To boot from the CF disk, be sure the mode jumper is inserted.
* The included CF already has all the necessary software installed in track 0. CPM2.2 distribution files are on drive B, CPM3 distribution files are on drive A.
* Refer to manual for software installation on a new CF
* when power is applied, the expected current is 300mA-400mA
* The signal assignment of the serial port is designed for the 6-pin CP2102 USB adapter below. Other USB adapter may also be used. Only three signals need to be connected: RxD, TxD and Ground.

![](https://github.com/Plasmode/Z280RC/blob/master/Manuals/CP2102_adapter.jpeg)
## ZZMon

When the board is powered up with the mode jumper installed and a properly programed CF inserted, the ZZMon power up sign on message will be displayed on the console:

```
TinyZZ Monitor v0.8 3/25/18

>
```
ZZMon commands are single letter either upper case or lower case. Depending on the commands, the monitor software will prompt for additional actions.

**H** gives short list of ZZMon commands:

```
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

>
```
Detailed description of ZZMon commands are in ZZMon manual.
## CP/M

To boot CP/M 2.2 type:

**b2 (press enter to execute)**

```
Copyright 1979 © by Digital Research
CP/M 2.2 for TinyZ280
3/25/18 3.5 meg RAMDisk

a>
```
CP/M 2.2 distribution files are in drive B:

```
a>b:
b>dir
B: ASM COM : BIOS ASM : CBIOS ASM : DDT COM
B: DEBLOCK ASM : DISKDEF LIB : DUMP COM : DUMP ASM
B: ED COM : LOAD COM : MOVCPM COM : PIP COM
B: STAT COM : SUBMIT COM : SYSGEN COM : XSUB COM
b>
```
To boot CP/M 3 (non banked), type:

**b3 (press enter to execute)**

```
CP/M V3.0 Loader
Copyright (C) 1998, Caldera Inc.

BIOS3 SPR E800 1000
BDOS3 SPR C900 1F00

50K TPA
Copyright 1979 © by Digital Research
CP/M 3 for TinyZ280 3/25/18 3.5meg RAMdisk
A> dir
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
A>
```
CP/M3 distribution files are stored in drive A and another copy in drive C.
RAM Drive

Drive E is the RAM drive. The 1.5meg CP/M RAM drive is physically located in memory 0x80000-0x1FFFFF. RAM drive's directory needs to be initialized to 0xE5. This is done with ZZMon using the command:

**xE (press enter to execute)** ←please note the drive letter E must be in upper case.
