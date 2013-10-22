all:
	lua symbols.lua generate > symbols.s
	lua main.lua ca65.lua > main.s
	cl65 -o RabbitFarm.nes -C nes.cfg main.s

clean:
	rm -f symbols.s
	rm -f main.s
	rm -f main.o
