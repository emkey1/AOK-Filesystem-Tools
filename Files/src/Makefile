# Makefile for the login wrappers
#
#
all: login_loop login_single idev_ip

clean: 
	rm login_loop login_single idev_ip

login_loop:  login_loop.c
	gcc -o login_loop login_loop.c

login_single: login_single.c
	gcc -o login_single login_single.c

idev_ip: idev_ip.c
	gcc -o idev_ip idev_ip.c

install:  all
	cp login_single login_loop ..
	cp idev_ip ../bin
