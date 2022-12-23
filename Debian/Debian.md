# Debian

## Services

The script in /etc/rc2.d/ssh doesnt trigger sshd
I found a hack workarround by triggering a script direcly from
inittab, /usr/loca/sbin/manual_services
To make it even more weird, sshd needs to be first stopped
then started twice to come to life

## Removable?

apts that can be removed to create a smaller FS whilst not making FS
unbootable, work in progress, and since most usage cases at this point
is probably devels, removing compilers might be counter productive.

```bash
locales
manpages-dev
gcc
binutils-i686-linux-gnu
cpp
cpp-8
dmsetup
dmidecode
rsyslog
make
libc-dev-bin
libgcc-8-dev
linux-libc-dev
kmod
manpages-dev
patch
udev
```

## Various notes

check /deb/pts
