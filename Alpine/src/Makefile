#
#	Makefile for the Alpine login wrappers
#

all: login.loop login.once

clean:
	rm login.loop login.once

login.loop:  login.loop.c
	gcc -o login.loop login.loop.c

login.once: login.once.c
	gcc -o login.once login.once.c

install:  all
	cp login.once ../Alpine/bin
	cp login.loop ../Alpine/bin
