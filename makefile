all: apple.prg
	 ../../x16emu-r40/x16emu.exe -prg apple.prg -run;

apple.prg: code.s
	cl65 code.s -o apple.prg -t cx16;
