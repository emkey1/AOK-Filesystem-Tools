# Makefile for the login wrappers
#
#
all: lib_fix

clean:
	rm lib_fix


lib_fix:  lib_fix.c
	gcc -o lib_fix lib_fix.c

install:  all
	cp lib_fix ../bin
