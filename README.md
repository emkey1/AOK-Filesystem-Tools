# AOK-Filesystems-Tools

## Recent changes

If /iCloud is not mounted, there will be a question if it is desired
to mount it right at the start of the install

-s (select distro) builds should be built on iSH/Linux (x86)
This way the boot image can be prepared, with whiptail being installed
and will boot straight into the Distro selection prompt.
If built on other devices, the resulting image will have to first
install newt, before offering the prompt.

It is assumed this is cloned into /opt/AOK

This makes deploys much easier since this location can be assumed,
regardless if it is run chrooted on a deploy platform, or if it is run
on destination

## Build process

Instructions on how to build an iSH family File system: `./build_fs -h`

## Configuration

Main settings are in AOK_VARS, BUILD_ENV have some build-related settings

You can override this with local settings in .AOK_VARS and .BUILD_ENV,
both will be ignored by git. Please note that if either is found,
it's content will be appended to the destination AOK_VARS/BUILD_ENV,
so motly for devel/debug. For production style deploys, it is recomended
to update AOK_VARS and not have a .AOK_VARS/.BUILD_ENV present.

## Further setup steps

To keep things simple /etc/profile is used to run additional setups
steps, since it will be run at bootup on iSH/iSH-AOK
Once setup is done /etc/profile will be replaced with the "normal" one.

## Multi distro

run build_fs -s to create a Distro asking if you want to use Alpine or
Debian

## Prebuilt FS

Both Alpine and Debian FS can be prebuilt. Advantage is that FS is ready
to be used right away, drawback is that the tarball will be larger.
In the case of Alpine, the initial FS Installing on first boot is only
arround 6MB, a pre-built AOK Alpine FS is something like 50MB.

With Debian the difference in size will be less noticeable, in both
cases it will be over 230MB

The recomended distribution method is to build with -s
Select between Alpine/Debian on first boot, initial tarball will be
arround 6MB.

### Running chrooted

When testing setups in a chroot env, some extra steps are needed,
since in chroot /etc/profile is not run

`sudo ./tools/do_chroot.sh /etc/profile`  Runs profile, ie next step of
deploy directly.

`sudo ./tools/do_chroot.sh /bin/ash`  There might not be a bash at
this point so must use /bin/ash if a shell is wanted, this also avoids
unintentionally running /etc/profile, if that is not desired, if the
setup has completed the default shell bash will run profile.
Using ash/sh as shell avoids this.

After Alpine / Debian is initially setup, bash will be
present so chroot can be done as `sudo ./tools/do_chroot.sh` to get a
normal session.

## Known Alpine issues

When Alpine login is enabled /etc/motd is not displayed, I have tried to
figure out a way to display it only on logins, but not come up with
a good way, when login is disabled, it is displayed.

## Debian

If your iOS device is on the slow end of things, you can avoid the
setup procedure on it by prepping it on a more capable device like this:

Be aware you can not cut-paste the entire sequence, since the exit needs
to be given to the chrooted process!

```
cd /opt/AOK
sudo ./build_fs -d -N
sudo ./tools/do_chroot.sh /etc/profile
exit

cd /tmp/AOK/iSH-AOK-FS

# Saves 50MB download, will be automatically recreated if missing
sudo rm var/cache/apt var/lib/apt -rf

sudo tar cvfz /tmp/DebPrepared.tgz .
```

and then import /tmp/DebPrepared.tgz as your FS

## Known Debian issues

### Login

The AOK alternate logins are not yet used, pending testing

### Services

Since iSH insta-terminates when you exit the console, this has some
impact on services:

- It can't be expected that shutdown cleanup will be done from within Debian
- If indeed init 0 or init 6 is done and as is normally the case umountfs
is defined. It will unmount /iCloud. Since there is (as far as I know)
no way to mount it via /etc/fstab during next startup, thus removing the
mount permanently, until manually added again.

Therefore /run is restored to a clean state via /etc/inittab during sysinit
in order to not trick openrc that services are already running.

Further, as of now all default services are initially disabled.

Most of them are related to booting the FS, networking,
setting up random numbers etc.
Tasks that are done by iOS and the iSH app itself.

Services can be added after setup, using something like
`rc-update add cron default`

runbg is installed and active from the start.
sshd is toggled by running: enable_sshd / disable_sshd

### Generic Debian Services found to be working inside iSH

- cron
- ssh

sshd is setup up by the AOK deploy, but not initially active.
It can be enabled / disabled by running enable_sshd / disable_sshd

### Specific iSH-AOK services

- runbg

I have tried to convert runbg to be a posix script
as is normally the case in Debian when using openrc
using the #!/bin/sh shebang, but so far no success.

So as of now I use the same here as for Alpine,
using a #!/sbin/openrc-run style script.
It seems to work fine, so there is that.
