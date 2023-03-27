# AOK-Filesystems-Tools

It is assumed this is cloned into /opt/AOK

Since various parts of this is both used in the initial build process on
the host platform, and also for finalizing the setup on the destination
platform. It must be located in a known location to be found.

## Recent changes

- logins supported by all three distros
- USER_SHELL allows setting the shell for the sample user

## Compatability

You can build the FS on any platform, but for chrooting (Prebuilding FS,
or testing) you need to use iSH or Linux(x86).

## Distros available

### Alpine FS

Fully usable

### Debian FS

Fully usable

#### Known Debian FS issues

##### Using Blink

When disconnecting from an iSH-AOK Debian FS session, it is left hanging.
You need to hit Enter to get back to the Blink prompt.

##### Building it

For now the two recomended and working build methods are:

- Build the FS on your iOS device, then mount the resulting FS image as a new FS & reboot into it
- Build the FS on a Linux (x86) node, then mount the resulting FS image as a new FS & reboot into it

These two methods have been tested and work both with and without the prebuilt option.

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
`/etc/hosts` can be used, and the hostnames needed for apt handling are
included, but this obviously is a rather limited solution to the DNS
issue, just a stopgap.

## Build process

Instructions on how to build an iSH family File system: `./build_fs -h`

## Multi distro

run `build_fs -s` to create a Distro asking if you want to use Alpine,
Debian or Devuan.

This is the recomended build method if you don't need to prebuild.
Initial tarball will be arround 8MB. Asuming the target device is
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

Simplest way to start using this overide file is to just copy AOK_VARS
into .AOK_VARS and then edit .AOK_VARS to match your needs.

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
