all: apple.prg
	 ../x16emu/x16emu.exe -prg apple.prg -run;

apple.prg: code.s
	cl65 code.s -o apple.prg;
