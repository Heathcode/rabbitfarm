all:
	lua symbols.lua generate > symbols.s
	lua main.lua ca65.lua > main.s
	ca65 main.s
	cl65 -o RabbitFarm.nes -C nes.cfg main.o

clean:
	rm -f symbols.s
	rm -f main.s
	rm -f main.o
