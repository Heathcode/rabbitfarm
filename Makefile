all:
	cc65 -Oi game.c --add-source
	ca65 crt0.s
	ca65 game.s
	cl65 -o RabbitFarm.nes -C nes.cfg crt0.o game.o

clean:
	rm -f *~
	rm -f *.o
	rm -f game.s
