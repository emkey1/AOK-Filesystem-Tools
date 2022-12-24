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

## Build times

At least older iPads are pathetically slow. Deploying a basic cloud host
even for just a few hours/days is a gigantic time saver if you experient
with building debian FS. For Alpine builds this is not that much of a
concern.

Additional benefit if you want to experiment with Debian, regardless if
you build on Linux or iOS, a pre built Debian just cost you the
extensive pain once, and can then be deployed fairly swiftly.
Installing a pre-built Debian even on my iPad is arround 5 mins.

Using a -s build (selection between Alpine & Debian on first boot.)
takes 25 mins just to download and unpack if you chose Debian on my iPad

-s is still the recomended build option, since it gives you late choice
of distro. And for Alpine there is no additional deploy time.

### debian bzip2


sudo ./build_fs -d -j

- Generic Linux cloud host (2vCPU 2G Ram): 58s
- iPad 5th gen:     37m 41s
