# AOK-Filesystems-Tools

It is assumed this is cloned into /opt/AOK

## Compatability

You can build the FS on any platform, but for chrooting (Prebuilding FS, or testing) you need to use iSH or Linux(x86).
Reportedly deploying the resulting FS does NOT work on Arm based MacBooks.

## Distros available

### Alpine

Fully usable

#### Known Alpine issues

When Alpine login is enabled /etc/motd is not displayed, I have tried to
figure out a way to display it only on logins, but not come up with
a good way, when login is disabled, it is displayed.

### Debian

Fully usable

#### Known Debian issues

##### Login

The AOK alternate logins are not yet used, pending testing

##### Specific iSH-AOK services

- runbg

I have tried to convert runbg to be a posix script
as is normally the case in Debian when using openrc
using the `#!/bin/sh` shebang, but so far no success.

So as of now I use the same here as for Alpine,
using a `#!/sbin/openrc-run` style script.
It seems to work fine, so there is that.

### Devuan

DNS resolving doesn't work, so whilst you can use Devuan,
without DNS it is not that usefull beyond testing ATM.

## Build process

Instructions on how to build an iSH family File system: `./build_fs -h`

## Multi distro

run `build_fs -s` to create a Distro asking if you want to use Alpine or
Debian

This is the recomended build method if you don't need to prebuild.
Initial tarball will be arround 10MB. Asuming the target device is
resonably modern, the deploy should not take too long.

## Prebuilt FS

Especially for slower devices this can be a huge time saver, if you build
the FS on a Linux (x86) with -p for prebuild, it takes only seconds, on a
iPad 5th Alpine takes 6-7 mins, Debian and Devuan takes a lot longer.

All provided distros can be prebuilt. Advantage is that FS is ready
to be used right away, drawback is that in most cases the FS tarball
 will be larger.

In the case of Alpine, the FS Installing on first boot is only
arround 6MB, a pre-built AOK Alpine FS is something like 50MB.

With Debian the difference in size goes from 125MB to 175MB

With Devuan the image is arround 85MB in both cases

## Configuration

Settings are in AOK_VARS

You can override this with local settings in .AOK_VARS, it will be
ignored by git. Please note that if this file is found,
it's content will be appended to the destination AOK_VARS & tools/utils.sh,
so motly for devel/debug. For production style deploys, it is recomended
to update AOK_VARS and not have a .AOK_VARS present.

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

#### License


[MIT](LICENSE)
