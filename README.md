# AOK-Filesystems-Tools

It is assumed this is cloned into /opt/AOK

## Compatability

You can build the FS on any platform, but for chrooting (pre-deployments, or testing) you need to use iOS/iPadOS or Linux(x86). 
Reportedly deploying the resulting FS does NOT work on Arm based MacBooks.

## Build process

Instructions on how to build an iSH family File system: `./build_fs -h`

The recomended distribution method is to build with -s
Select between Alpine/Debian on first boot, initial tarball will be
arround 10MB. Asuming the target device is resonably modern, the
deploy should not take too long.

## Prebuilt FS

Both Alpine and Debian FS can be prebuilt. Advantage is that FS is ready
to be used right away, drawback is that the FS tarball will be larger.

Especially for slower devices this can be a huge time saver.

In the case of Alpine, the FS Installing on first boot is only
arround 6MB, a pre-built AOK Alpine FS is something like 50MB.

With Debian the difference in size goes from 125MB to 175MB

## Configuration

Settings are in AOK_VARS

You can override this with local settings in .AOK_VARS, it will be
ignored by git. Please note that if this file is found,
it's content will be appended to the destination AOK_VARS & tools/utils.sh,
so motly for devel/debug. For production style deploys, it is recomended
to update AOK_VARS and not have a .AOK_VARS present.

## Multi distro

run build_fs -s to create a Distro asking if you want to use Alpine or
Debian

### Running chrooted

When testing setups in a chroot env, some extra steps are needed,
since in chroot /etc/profile might not run, depending on shell use.

`sudo ./tools/do_chroot.sh /etc/profile`  Runs profile, ie next step of
deploy directly, if any steps remain.

`sudo ./tools/do_chroot.sh /bin/ash`  There might not be a bash available
at this point, on Alpine /bin/ash is always present, for Debian /bin/sh
has to be used. This also avoids unintentionally running /etc/profile,
if that is not desired.

After Alpine / Debian setup is completed, bash can be used
`sudo ./tools/do_chroot.sh` defaults to use bash if no command is specified.

## Known Alpine issues

When Alpine login is enabled /etc/motd is not displayed, I have tried to
figure out a way to display it only on logins, but not come up with
a good way, when login is disabled, it is displayed.

## Known Debian issues

### Login

The AOK alternate logins are not yet used, pending testing

#### Specific iSH-AOK services

- runbg

I have tried to convert runbg to be a posix script
as is normally the case in Debian when using openrc
using the `#!/bin/sh` shebang, but so far no success.

So as of now I use the same here as for Alpine,
using a `#!/sbin/openrc-run` style script.
It seems to work fine, so there is that.
