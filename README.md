# AOK-Filesystems-Tools

It is assumed this is cloned into /opt/AOK

## Build process

Instructions on how to build an iSH family File system: `./build_fs -h`

The recomended distribution method is to build with -s
Select between Alpine/Debian on first boot, initial tarball will be
arround 6MB. Asuming the target device is resonably modern, the
deploy should not take too long.

## Prebuilt FS

Both Alpine and Debian FS can be prebuilt. Advantage is that FS is ready
to be used right away, drawback is that the FS tarball will be larger.

Especially for slower devices this can be a huge time saver.

In the case of Alpine, the initial FS Installing on first boot is only
arround 6MB, a pre-built AOK Alpine FS is something like 50MB.

With Debian the difference in size will be less noticeable, it goes
from 125MB to 175MB

## Configuration

Settings are in AOK_VARS

You can override this with local settings in .AOK_VARS, it will be
ignored by git. Please note that if this file is found,
it's content will be appended to the destination AOK_VARS/build_env,
so motly for devel/debug. For production style deploys, it is recomended
to update AOK_VARS and not have a .AOK_VARS present.

## Further setup steps

To keep things simple /etc/profile is used to run setup on dest
platform, since it will be run at bootup on iSH/iSH-AOK
Once setup is done /etc/profile will be replaced with the "normal" one.

## Multi distro

run build_fs -s to create a Distro asking if you want to use Alpine or
Debian

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

Be aware you can't cut-paste the entire sequence, since the exit needs
to be given to the chrooted process!

```bash
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

Therefore /run/openrc is removed via /etc/inittab during sysinit
in order to not trick openrc that services are already running.

Services initially active

- runbg

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
