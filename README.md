# AOK-Filesystems-Tools

The aim of this is to create a consistent iSH environment that provides a mostly normal Linux experience, minus the obvious lack of a GUI.

You can select what distro to base your File System on, so far Alpine and Debian are fully usable. They offer a very similar user experience. More or less the same apps are installed, and they offer the same custom tools. Alpine uses fewer resources, so things will be a bit "faster," but in the iSH universe, speed is a relative concept.

## Disclaimer

I typically work on this on a workstation and test it on multiple devices to ensure it functions as intended in various scenarios. I don't use branches extensively to isolate experimental changes. If you want to try it out, I recommend starting with the latest release. These releases are thoroughly tested and should be stable. While the main branch usually works fine, there are no guarantees.

## Installation

### Getting the Repository

For general usage, it is recommended to use the latest release, as mentioned in the Disclaimer. Once you have downloaded it, follow these steps (please note that release numbers change over time):

```sh
unzip AOK-Filesystem-Tools-0.9.2.zip 
sudo rm -rf /opt/AOK  # Remove the previous instance if present
sudo mv AOK-Filesystem-Tools-0.9.2 /opt/AOK
```

To try out the latest changes:

```sh
git clone https://github.com/jaclu/AOK-Filesystem-Tools.git 
sudo rm -rf /opt/AOK  # Remove the previous instance if present
sudo mv AOK-Filesystem-Tools /opt/AOK
```

Please ensure that this is located in /opt/AOK, as various parts of the tool rely on its known location.

## Compatability

You can build the file system on any platform, but for chrooting, so that you can pre build, and/or run the dest env on the build platform, you need to build on iSH or Linux (x86).

## Available Distros

### Alpine File System

Fully usable. Release can be selected in AOK_VARS

### Debian File System

Fully usable. Be aware that this is Debian 10, since that was the last version of Debian for 32-bit environs. Deb 10 has been end of lifed, so will no longer recieve updates, but you are unlikely to run any public services on iSH, so for experimenting with a local Debian, it should be fine.

### Devuan File System

DNS resolving doesn't work, so while you can use Devuan, it's not very useful beyond testing at the moment. You can use `/etc/hosts`, to add hosts, and the hostnames needed for apt handling are included, but this is a limited solution to the DNS issue.

## Build Process

For instructions on how to build an AOK File System, run:

```sh
./build_fs -h
```

### Choosing Distro When You First Boot the File System

To create a File system allowing you to choose between Alpine, Debian, or Devuan when iSH first boots it up use:

```sh
build_fs -s
```

This is the recommended build method if you don't need to prebuild. The initial tarball will be around 8MB, and assuming the target device is reasonably modern, the setup should not take too long.

## Configuration

Settings are in `AOK_VARS`. You can override these with local settings in `.AOK_VARS`, which will be ignored by Git.

The simplest way to start using this override file is to copy `AOK_VARS` into `.AOK_VARS` and then edit `.AOK_VARS` to match your needs.

## Running Chrooted

The default command when running `do_chroot.sh` is to examine /etc/password on the dest_fs and select the shell used by root.

When testing setups in a chroot environment, some extra steps might be needed to complete the deploy. Any remaining deploy steps are copied to /etc/profile

If you start with a shell not running /etc/profile, the deploy will not progress. If that happens, it is not much of an issue. Just exit the chroot and run


```bash
./tools/do_chroot.sh /etc/profile
```

#### License

[MIT](LICENSE)
