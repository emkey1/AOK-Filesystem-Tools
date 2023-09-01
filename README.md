# AOK-Filesystems-Tools

This creates a consistent iSH environment aimed at giving a mostly normal Linux experience, minus the obvious lack of a GUI.

It can be based on several distros, primarily Alpine & Debian, and should give a very similar user experience on either.
Alpine uses fewer resources, so things will be a bit "faster", but in the iSH universe faster is a very relative concept.

## Disclaimer

Since I tend to work on this on a workstation, then test it on multiple devices to see if the change works as intended in 
various scenarios, I dont use branches much to isolate experimental stuff. If you want to try it out, start by using 
the latest release. They are thorougly tested and should be fully stable.
Most of the time the main branch will work fine, but there are no guarantees...

## Installation

### Get the repo

```bash
git clone https://github.com/jaclu/AOK-Filesystem-Tools.git 
sudo rm -rf /opt/AOK  # remove the previous instance if present
sudo mv AOK-Filesystem-Tools /opt/AOK
```

It is assumed this is located at /opt/AOK

Since various parts of this are both used in the initial build process on the host platform, 
and also for finalizing the setup on the destination platform. 
It must be located in a known location for it to be found.

### To prebuild your FS or not

The reason you might want to prebuild your FS is that the processing speed in the iSH family of apps is ridiculously slow,
even a low-end Linux node would prepare the FS perhaps 100 times faster than a modern iPad.
By prebuilding, almost everything needed to set up the environment is done in advance. And only the final steps that must be done on the destination device have to be performed during 1st boot. Things like selecting a timezone, deciding if /iCloud should be mounted, and detecting if this is iSH-AOK or iSH. In the case of iSH, all packets only supported by iSH-AOK are removed.

One potential drawback is that a prebuilt FS will be much larger, but you would not save any download time, since by doing the full deployment on the iOS device, it would have to download the same content anyhow.

The end result is the same regardless if you prebuild or not. 
However, the deployment of a prebuilt FS is significantly faster. 
If your build env can't do it, this is not the end of things. 

### Test to see if your env can do pre-build

This just tries to prepare an Alpine FS without compressing it, if you get no error msg your system supports pre build

```bash
/opt/AOK/build_fs -N -p
```

If you see a build happening, your environment is able to prebuild file systems. 
Add -p to build_fs whenever you want to use prebuilding.

If you see this, then prebuilding is not an option in this system

```bash
Unfortunately, you can not chroot into the image on this device
This is only supported on iSH and Linux(x86)
Use another build option (try -h for help)

ERROR: Failed to sudo run: /opt/AOK/build_fs
```

## Experimenting with generating your own FS

First, create your local config file, this will not collide with the git repository, and if you update it will not be touched

```bash
cp /opt/AOK/AOK_VARS /opt/AOK/.AOK_VARS
```

Next Edit /opt/AOK/.AOK_VARS to your liking,  like selecting what Alpine release should be installed, etc. 
Everything should hopefully be explained, if anything is unclear file an issue.

### Building Alpine

```bash
/opt/AOK/build_fs -p
```

### Building Debian

```bash
/opt/AOK/build_fs -p -d
```

### Choose distro

Convenient in the sense that this delays Distro selection, however, install times will be significantly longer for Debian
```bash
/opt/AOK/build_fs -s
```

## Recent Changes
- tools/do_chroot.sh rewritten, takes better care to release mounts
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

### Devuan FS

No dns support, not meaningfull beyond experimenting

### Specific iSH-AOK services

- runbg

I have tried to convert runbg to be a posix script
as is normally the case in Debian when using openrc.
Using the `#!/bin/sh` shebang, but so far no success.

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

## Select Distro

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

With Debian the difference in size is relatively small, since it comes
with all the packages needed for AOK pre-installed. 350MB

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

## Running chrooted

When testing setups in a chroot env, some extra steps are needed,
since in chroot /etc/profile might not run, depending on shell use.

`./tools/do_chroot.sh /etc/profile`  Runs profile, i.e. next step of
deploy directly, if any steps remain.

`./tools/do_chroot.sh /bin/ash`  There might not be a bash available
at this point, on Alpine /bin/ash is always present, for Debian /bin/sh
has to be used. This also avoids unintentionally running /etc/profile,
if that is not desired.

After Alpine / Debian setup is completed, bash can be used
`./tools/do_chroot.sh` defaults to use bash if no command is specified.

#### License

[MIT](LICENSE)
