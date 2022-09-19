all: APPLE.PRG
	 /mnt/d/x16emu-r41/x16emu.exe -prg APPLE.PRG -run;

APPLE.PRG: code.s
	cl65 code.s -o APPLE.PRG -t cx16;
