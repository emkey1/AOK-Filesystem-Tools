# Makefile for the login wrappers
#
#
all: login.loop login.once idev_ip

clean:
	rm login.loop login.once idev_ip

login.loop:  login.loop.c
	gcc -o login.loop login.loop.c

login.once: login.once.c
	gcc -o login.once login.once.c

idev_ip: idev_ip.c
	gcc -o idev_ip idev_ip.c

install:  all
	cp login.once ../Alpine/bin
	cp login.loop ../Alpine/bin
	cp idev_ip ../Alpine/usr_local_bin
