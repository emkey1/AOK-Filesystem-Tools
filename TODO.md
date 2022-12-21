# TODO

Debian image

- remove /etc/aok_release
- uninstall openrc



- wget https://www.dropbox.com/s/1b47i983pbg9zna/Debian_10_i386_iSH-AOK_B2.tar.bz2

- tar xvfj Debian_10_i386_iSH-AOK_B2.tar.bz2

- rsync -ahP opt_AOK [chroot_env]/opt

- Fix devices with: `/opt/AOK/bin/dev_fix.sh`


```bash
# Host
cd opt_AOK/deb_root_home
sudo cp -av .bashrc [chroot_env]/root
```

comment out line: mesg n || true in /root/.profile to get rid of warning

Edit /etc/apt/sources.list

comment out deb-src sources unless you really want source repos

```bash
# Only clear all old caches if you want to get a fresh start for the apt index
rm /var/cache/apt /var/lib/apt -rf

apt update && apt upgrade`
```

Remove stuff from the original AOK Debian image that are not of general usage,
those so inclined can install if wanted.

```
binutils-i686-linux-gnu
cpp-8
cpp
kmod
linux-libc-dev
make
manpages-dev
patch
udev
```

- Nothing atm.


check /deb/pts
