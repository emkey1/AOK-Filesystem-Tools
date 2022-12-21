# AOK-Filesystems-Tools

## Recent changes

It is assumed this is cloned into /opt/AOK

This makes deploys much easier since this location can be assumed, regardless if it is run chrooted on a deploy platform, or if it is run inside iSH


## Multi distro

run build_fs -d to create a Distro asking if you want to use Alpine or Debian

### Running multi-boot chrooted

When testing distro select in a chroot env, some extra steps are needed,
since in chroot /etc/profile is not run

`sudo ./tools/do_chroot.sh /etc/profile`  Runs profile, ie setup directly

`sudo ./tools/do_chroot.sh /bin/sh`  There is no bash at this point so must use /bin/sh if a shell is wanted

When rebooting after Alpine / Debian is initially setup, bash will be present
so second chroot can be `sudo ./tools/do_chroot.sh` in order to trigger
/etc/profile, which might contain remaining deploy steps


## Known Debian issues

### login

The AOK alternate logins are not yet deployed, pending testing

### services

The service handling on iSH Debian is not yet done

## Build process

Instructions on how to build an iSH family File system: `./build_fs -h`

Further instructions will be displayed when this is run

## Configuration

Tweak build settings in `./AOK_VARS`

You can override this with local settings in .AOK_VARS

## Tool Versions

Check with -h or -v

If you don't have the latest version of the script you intend to use,
update your repository!

Vers | script
-|-
1.3.4 | build_fs
1.3.3 | Alpine/setup_alpine_env
1.3.3 | compress_image
1.3.0 | tools/do_chroot.sh
1.1.3 | tools/shellchecker.sh
