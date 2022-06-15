#!/bin/sh

#
#  if $1 param is supplied run that in the chroot, otherwise default to bash -l
#

#  shellcheck disable=SC1007
CURRENT_D=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FS_BUILD_D="$(dirname "$CURRENT_D")"

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else.
#
cd "$FS_BUILD_D" || exit 1

#  shellcheck disable=SC1091
. "$FS_BUILD_D"/BUILD_ENV

if [ "$(whoami)" != "root" ]; then
    echo "ERROR: This must be run as root or using sudo!"
    echo
    exit 1
fi

echo "=====  Preparing the environment for chroot  ====="

echo "---  Setting up needed /dev items  ---"

mknod "$BUILD_ROOT_D"/dev/null c 1 3
chmod 666 "$BUILD_ROOT_D"/dev/null

mknod "$BUILD_ROOT_D"/dev/urandom c 1 9
chmod 666 "$BUILD_ROOT_D"/dev/urandom

mknod "$BUILD_ROOT_D"/dev/zero c 1 5
chmod 666 "$BUILD_ROOT_D"/dev/zero


echo "---  Mounting proc  ---"

mount -t proc proc "$BUILD_ROOT_D"/proc
# mount -o bind /tmp /tmp/AOK/iSH-AOK-FS/tmp
mount -t sysfs sys /tmp/AOK/iSH-AOK-FS/sys
mount -o bind /dev /tmp/AOK/iSH-AOK-FS/dev

if [ "$1" = "" ]; then
    cmd="bash -l"
else
    cmd="$1"
fi

echo "=====  Do the chroot  ====="

# In this case we want the variable to expand into its components
# shellcheck disable=SC2086
chroot "$BUILD_ROOT_D" $cmd
exit_code="$?"


echo
echo "=====  Doing some post chroot cleanup  ====="

echo "---  Un-mounting proc  ---"

umount /tmp/AOK/iSH-AOK-FS/proc
# umount /tmp/AOK/iSH-AOK-FS/tmp
umount /tmp/AOK/iSH-AOK-FS/sys
umount /tmp/AOK/iSH-AOK-FS/dev

echo "---  Removing the temp /dev entries"
rm -f "$BUILD_ROOT_D"/dev/*

# If there was an error in the chroot process, propagate it
exit "$exit_code"
