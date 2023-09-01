# AOK-Filesystems-Tools

AOK Filesystems Tools aim to create a consistent iSH environment that provides
a mostly normal Linux experience, minus the obvious lack of a GUI.

These tools are designed to work with various Linux distributions, so far
Alpine and Debian, offering a very similar user experience on both. Alpine uses
fewer resources, so things will be a bit "faster," but in the iSH universe,
speed is a relative concept.

## Disclaimer

I typically work on this on a workstation and test it on multiple devices to
ensure it functions as intended in various scenarios. I don't use branches
extensively to isolate experimental changes. If you want to try it out, I
recommend starting with the latest release. These releases are thoroughly
tested and should be stable. While the main branch usually works fine, there
are no guarantees.

## Installation

### Getting the Repository

For general usage, it is recommended to use the latest release, as mentioned in
the Disclaimer. Once you have downloaded it, follow these steps (please note
that release numbers may change):

```sh
unzip AOK-Filesystem-Tools-0.9.2.zip 
sudo rm -rf /opt/AOK  # Remove the previous instance if present
sudo mv AOK-Filesystem-Tools-0.9.2 /opt/AOK
```

To try out the latest changes, you can use Git clone:

```sh
git clone https://github.com/jaclu/AOK-Filesystem-Tools.git 
sudo rm -rf /opt/AOK  # Remove the previous instance if present
sudo mv AOK-Filesystem-Tools /opt/AOK
```

Please ensure that this is located in /opt/AOK, as various parts of the tool
rely on its known location.

### To Prebuild Your File System or Not

You might consider prebuilding your file system due to the slow processing
speed in iSH apps. Even a low-end Linux node can prepare the file system about
10 times faster than a modern iPad. Prebuilding involves completing almost
everything needed to set up the environment in advance, with only final steps,
like selecting a timezone, deciding if /iCloud should be mounted, and detecting
whether this is iSH-AOK or iSH, left to be performed during the first boot. In
the case of iSH, all packets only supported by iSH-AOK are removed.

One potential drawback is that a prebuilt file system will be much larger, but
it won't waste download time since the content still needs to be downloaded
during the full deployment on the iOS device.

The end result is the same whether you prebuild or not. However, deploying a
prebuilt file system is significantly faster. If your build environment can't
prebuild, don't worry; there are other options.

### Testing for Prebuild Compatibility

You can test if your environment supports prebuilding by running the following
command:

```bash
/opt/AOK/build_fs -N -p
```

If you see a build happening, your environment supports prebuilding. You can
add -p to `build_fs` whenever you want to use prebuilding.

If you see the following message, prebuilding is not an option in your system:

```bash
Unfortunately, you cannot chroot into the image on this device.
This is only supported on iSH and Linux(x86).
Use another build option (try -h for help).

ERROR: Failed to sudo run: /opt/AOK/build_fs
```

## Experimenting with Generating Your Own File System

First, create your local config file; this won't interfere with the Git
repository and won't be touched if you update it:

```bash
cp /opt/AOK/AOK_VARS /opt/AOK/.AOK_VARS
```

Next, edit `/opt/AOK/.AOK_VARS` to your liking, such as selecting which Alpine
release should be installed, and so on. Everything should be explained, but if
anything is unclear, feel free to file an issue.

### Building Alpine

```bash
/opt/AOK/build_fs -p
```

### Building Debian

```bash
/opt/AOK/build_fs -p -d
```

### Choosing the Distro

Conveniently, you can delay distro selection with this option, but installation
times will be significantly longer for Debian:

```bash
/opt/AOK/build_fs -s
```

## Recent Changes

- `tools/do_chroot.sh` has been rewritten to better handle mounts.
- Logins are now supported by all three distros.
- `USER_SHELL` allows setting the shell for the sample user.

## Compatability

You can build the file system on any platform, but for chrooting, prebuilding
the file system, or testing, you need to use iSH or Linux (x86).

## Available Distros

### Alpine File System

Fully usable.

### Debian File System

Fully usable.

- `runbg`

I've attempted to convert `runbg` to be a POSIX script, as is typically the
case in Debian when using OpenRC. I've used the `#!/bin/sh` shebang, but so
far, I haven't had success. For now, I'm using the same approach as in Alpine,
employing a `#!/sbin/openrc-run` style script, which seems to work fine.

### Devuan File System

DNS resolving doesn't work, so while you can use Devuan, it's not very useful
beyond testing at the moment. You can use `/etc/hosts`, and the hostnames
needed for apt handling are included, but this is a limited solution to the
DNS issue.

## Build Process

For instructions on how to build an iSH family file system, run:

```sh
./build_fs -h
```

## Selecting the Distro

To create a File system allowing you to choose between Alpine, Debian, or Devuan, run:

```sh
build_fs -s
```

This is the recommended build method if you don't need to prebuild. The initial
tarball will be around 8MB, and assuming the target device is reasonably
modern, the deployment should not take too long.

## Prebuilt File Systems

Especially for slower devices, prebuilt file systems can be a huge time saver.
If you build the file system on a Linux (x86) machine with the `-p` flag for
prebuilding, it only takes seconds, whereas on an iPad 5th generation, Alpine
takes 6-7 minutes, and Debian and Devuan take much longer.

All provided distros can be prebuilt. The advantage is that the file system is
ready to be used immediately, but the drawback is that the file system tarball
will be larger. For example, with Alpine, the FS installing on the first boot
is only around 6MB, while a prebuilt AOK Alpine FS is around 50MB. With Debian,
the difference in size is relatively small, as it comes with all the packages
needed for AOK pre-installed (approximately 350MB). With Devuan, the image is
around 85MB in both cases.

## Configuration

Settings are in `AOK_VARS`. You can override these with local settings in
`.AOK_VARS`, which will be ignored by Git. Please note that if this file is
found, its content will be appended to the destination `AOK_VARS` and
`tools/utils.sh`. This is mainly for development and debugging purposes. For
production-style deploys, it is recommended to update `AOK_VARS` and not have a
`.AOK_VARS` file present.

The simplest way to start using this override file is to copy `AOK_VARS` into
`.AOK_VARS` and then edit `.AOK_VARS` to match your needs.

## Running Chrooted

When testing setups in a chroot environment, some extra steps are needed
because `/etc/profile` might not run depending on the shell in use.

To run `/etc/profile`, wich triggers the next step of deployment directly,
if any steps remain:

```bash
./tools/do_chroot.sh /etc/profile
```

To run `/bin/ash` (there might not be a Bash available at this point; on
Alpine, `/bin/ash` is always present, and for Debian, `/bin/sh` has to be
used). This also avoids unintentionally running `/etc/profile` if that is not
desired:

```bash
./tools/do_chroot.sh /bin/ash
```

After Alpine or Debian setup is completed, you can use Bash:

```bash
./tools/do_chroot.sh
```

#### License

[MIT](LICENSE)
