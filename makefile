all: APPLE.PRG sound
	 

APPLE.PRG: code.s
	cl65.exe code.s -o APPLE.PRG -t cx16;

sound: APPLE.RAW
	cp Bad_Apple.raw APPLE.RAW

run: APPLE.PRG sound
	/mnt/d/box16/box16.exe -prg APPLE.PRG -run;
