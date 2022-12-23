# Debian

## bin

some Debian specific stuff, will be copied to /usr/local/bin

## src

source files for stuff compiled into bin

## deb_root_home

mkeys prefered root env

## debian_first_boot.sh

Run as /etc/profile on first boot, to finalize migration from the initial
minimal Alpine FS into a pure Debian one

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
