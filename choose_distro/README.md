## chrooting

When testing distro select in a chroot env, some extra steps are needed,
since in chroot /etc/profile is not run

`sudo ./tools/do_chroot.sh /bin/sh`  There is no bash at this point so must use /bin/sh

`sh /etc/profile` Manually run it, normally it will be auto-run

