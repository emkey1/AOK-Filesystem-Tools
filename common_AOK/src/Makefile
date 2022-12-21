# Makefile for the login wrappers
#
#
all: idev_ip

clean:
	rm idev_ip

idev_ip: idev_ip.c
	gcc -o idev_ip idev_ip.c -static
	strip idev_ip

# install:  all
# 	mv idev_ip /usr/local/bin
# 	chmod 755 /usr/local/bin/idev_ip
