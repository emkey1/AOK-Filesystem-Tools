#!/bin/sh
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#  Version: 1.2.0 2022-06-19
#
#  if $1 is -p $2 is assumed to be the path to chroot in-to, it defaults to
#  BUILD_ROOT_D if not given. After -p and the dir is processed those two
#  parameters are shifted, so the potential command to be run should be given
#  after this.
#
#  If (what is now) $1 param is supplied, run that command in the chroot,
#  otherwise default to bash -l, if more than one word, the command and its
#  parameters needs to be quoted: '/bin/sh -l'
#

#  shellcheck disable=SC1007
CURRENT_D=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FS_BUILD_D="$(dirname "$CURRENT_D")"

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else.
#
cd "$FS_BUILD_D" || exit 1

# shellcheck disable=SC1091
. ./BUILD_ENV


if [ "$(whoami)" != "root" ]; then
    echo "ERROR: This must be run as root or using sudo!"
    echo
    exit 1
fi

CHROOT_TO="$BUILD_ROOT_D"
if [ "$1" = "-p" ]; then
    if [ -n "$2" ]; then
        CHROOT_TO="$2"
        if [ ! -d "$CHROOT_TO" ]; then
            echo "ERROR: [$CHROOT_TO] is not a directory!"
            exit 1
        fi
        shift # get rid of the param
        shift # get rid of the dir
    else
        echo "ERROR: -p assumes a param pointing to where to chroot!"
        exit 1
    fi
fi

echo "=====  Preparing the environment for chroot  ====="


echo "---  Mounting system resources  ---"

mount -t proc proc "$CHROOT_TO"/proc

if [ -d "/proc/ish" ]; then
    echo "---  Setting up needed /dev items  ---"

    mknod "$CHROOT_TO"/dev/null c 1 3
    chmod 666 "$CHROOT_TO"/dev/null

    mknod "$CHROOT_TO"/dev/urandom c 1 9
    chmod 666 "$CHROOT_TO"/dev/urandom

    mknod "$CHROOT_TO"/dev/zero c 1 5
    chmod 666 "$CHROOT_TO"/dev/zero
else
    # mount -o bind /tmp "$CHROOT_TO"/tmp
    mount -t sysfs sys "$CHROOT_TO"/sys
    mount -o bind /dev "$CHROOT_TO"/dev
fi


if [ "$1" = "" ]; then
    cmd="bash -l"
else
    cmd="$1"
fi


echo "=====  chrooting to: $CHROOT_TO ($cmd)  ====="


# In this case we want the variable to expand into its components
# shellcheck disable=SC2086
chroot "$CHROOT_TO" $cmd
exit_code="$?"


echo
echo "=====  Doing some post chroot cleanup  ====="


echo "---  Un-mounting system resources  ---"

umount "$CHROOT_TO"/proc

if [ -d "/proc/ish" ]; then
    echo "---  Removing the temp /dev entries"
    rm -f "$CHROOT_TO"/dev/*
else
    # umount "$CHROOT_TO"/tmp
    umount "$CHROOT_TO"/sys
    umount "$CHROOT_TO"/dev
fi


# If there was an error in the chroot process, propagate it
exit "$exit_code"
