# Debian

## Generic Debian Services useable inside iSH

- cron
- ssh

sshd is setup up by the AOK deploy, but not active.
It can be enabled / disabled by running enable_sshd / disable_sshd

### Specific iSH-AOK services

- runbg

## Removable?

apts that can be removed to create a smaller FS whilst not making FS
unbootable, work in progress, and since most usage cases at this point
are probably devels, removing compilers might be counter productive.

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

## Build times

At least older iPads are pathetically slow. Deploying a basic cloud host
even for just a few hours/days is a gigantic time saver if you are
building Debian FS. For Alpine builds this is not that much of a
concern.

Additional benefit if you want to experiment with Debian, regardless if
you build on Linux or iOS, a pre built Debian just cost you the
extensive pain once, and can then be deployed fairly swiftly.
Installing a pre-built Debian even on my iPad is arround 10 mins.

Using a -s build (selection between Alpine & Debian on first boot.)
takes 25 mins just to download and unpack if you chose Debian on my iPad

-s is still the recomended general build option, since it gives you late
choice of distro. And for Alpine there is no additional deploy time.

### debian bzip2

Creates smaller tarballs, but should probably only be used for multi or
Debian builds, since Alpine builds can run on general iSH as long as
it is not packed with bzip2. The iPad builds bellow are done with
togglr_multicore off, since with it on, iSH-AOK craches constantly on my
iPad, no doubt it will be quicker if this is not set


sudo ./build_fs -d -j

build times, regular tar inside parenthisis
- Generic Linux cloud host (2vCPU 2G Ram): 59s (43s)
- iPad 5th gen:     37m 41s
