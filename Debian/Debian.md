# Debian

## Removable?

I am experimenting to see what apts can be removed in order to create
a smaller FS distribution, whilst not making FS unbootable.
Installing them again during setup.

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
experimenting with building AOK FS for Debian.
For Alpine builds this is not that much of a concern.
On a normal cloud node build time is in the 20s range, then the time to
download the image. Compared to +30 min build time on my iPad 5th.

Additional benefit if you want to experiment with Debian, regardless if
you build on Linux or iOS, a pre built Debian just cost you the
extensive pain once, and can then be deployed fairly swiftly.
Installing a pre-built Debian even on my iPad is arround 10 mins.

Using a -s build (selection between Alpine & Debian on first boot.)
takes 25 mins just to download and unpack if you chose Debian on my iPad
On more modern hardware it can be assumed to be much swifter.

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
