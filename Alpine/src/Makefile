# Makefile for the login wrappers
#
#
all: login.loop login.once idev_ip

clean:
	rm login.loop login.once idev_ip

login.loop:  login.loop.c
	gcc -o login.loop login.loop.c -static
	strip login.loop

login.once: login.once.c
	gcc -o login.once login.once.c -static
	strip login.once

idev_ip: idev_ip.c
	gcc -o idev_ip idev_ip.c -static
	strip idev_ip

install:  all
	cp login.once ..
	cp login.loop ..
	cp idev_ip ../bin
