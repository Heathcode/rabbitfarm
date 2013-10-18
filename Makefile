all:
	ca65 crt0.s
	cl65 -o RabbitFarm.nes -C nes.cfg crt0.o

clean:
	rm -f *~
	rm -f *.o
