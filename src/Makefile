#
# 	idev_ip is used to detect ip# on iSH-AOK kernels
# 	This Makefile can not have an install clause, since
# 	depending on it being compiled
#	for Alpine the resulting bin should go to Alpine/usr_local_bin
#	for Debian the resulting bin should go to Debian/usr_local_bin
#	So in order to deploy the bin, you need to compile it on the
#	desired distro, then making sure the bin is picked up at the right
#	location by the git-repo
#
all: idev_ip

clean:
	rm idev_ip

idev_ip: idev_ip.c
	gcc -o idev_ip idev_ip.c

install_alpine:  all
	cp idev_ip ../Alpine/usr_local_bin

install_debian:  all
	cp idev_ip ../Debian/usr_local_bin
