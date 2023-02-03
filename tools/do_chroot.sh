#!/bin/sh
# shellcheck disable=SC2154

#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Tries to ensure a successful chroot both on native iSH and on Linux (x86)
#  by allocating and freeing OS resources needed.
#
version="1.4.0a"

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

if [ "$build_env" -eq 0 ]; then
    echo
    echo "AOK can only be chrooted on iSH or Linux (x86)"
    echo
    exit 1
fi

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else, this to ensure build_env can be found
#
cd "$aok_content" || exit 99

prog_name=$(basename "$0")

CHROOT_TO="$build_root_d"

if [ "$(whoami)" != "root" ]; then
    error_msg "This must be run as root or using sudo!"
fi

env_prepare() {
    # msg_2 "Preparing the environment for chroot"

    # msg_3 "Mounting system resources"

    mount -t proc proc "$CHROOT_TO"/proc

    if [ "$build_env" -eq 1 ]; then
        # msg_3 "Setting up needed /dev items"

        mknod "$CHROOT_TO"/dev/null c 1 3
        chmod 666 "$CHROOT_TO"/dev/null

        mknod "$CHROOT_TO"/dev/urandom c 1 9
        chmod 666 "$CHROOT_TO"/dev/urandom

        mknod "$CHROOT_TO"/dev/zero c 1 5
        chmod 666 "$CHROOT_TO"/dev/zero
    else
        mount -t sysfs sys "$CHROOT_TO"/sys
        mount -o bind /dev "$CHROOT_TO"/dev
    fi
    # msg_3 "copying current /etc/resolv.conf"
    cp /etc/resolv.conf "$CHROOT_TO/etc"
}

env_cleanup() {
    msg_2 "Doing some post chroot cleanup"

    # msg_3 "Un-mounting system resources"
    umount "$CHROOT_TO"/proc

    if [ "$build_env" -eq 1 ]; then
        msg_3 "Removing the temp /dev entries"
        rm -rf "${CHROOT_TO:?}"/dev/*
    else
        msg_3 "Unmounting /sys & /dev"
        umount "$CHROOT_TO"/sys
        umount "$CHROOT_TO"/dev
    fi
}

show_help() {
    cat <<EOF
Usage: $prog_name [-h] | [-v] | [-c] | [-p dir] command

chroot with env setup so this works on both Linux & iSH

Available options:

-h  --help     Print this help and exit
-v  --version  Display version and exit
-c  --cleanup  Cleanup env
-p, --path     What dir to chroot into, defaults to: $build_root_d
command        What to run, defaults to "bash -l", command and params must be quoted!
EOF

}

#===============================================================
#
#   Main
#
#===============================================================

case "$1" in

"-h" | "--help")
    show_help
    exit 0
    ;;

"-v" | "--version")
    echo "$prog_name, version $version"
    echo
    exit 0
    ;;

"-p" | "--path")
    if [ -n "$2" ]; then
        CHROOT_TO="$2"
        if [ ! -d "$CHROOT_TO" ]; then
            echo "ERROR: [$CHROOT_TO] is not a directory!"
            exit 1
        fi
        shift # get rid of the option
        shift # get rid of the dir
    else
        error_msg "-p assumes a param pointing to where to chroot!"
    fi
    ;;

"-c" | "--cleanup")
    env_cleanup
    exit 0
    ;;

*)
    firstchar="$(echo "$1" | cut -c1-1)"
    if [ "$firstchar" = "-" ]; then
        error_msg "invalid option! Try using: -h"
    fi
    ;;

esac

env_prepare

if [ "$1" = "" ]; then
    cmd="bash -l"
else
    cmd="$1"
fi

msg_1 "chrooting: $CHROOT_TO ($cmd)"

bldstat_set "$status_is_chrooted"

#  In this case we want the $cmd variable to expand into its components
#  shellcheck disable=SC2086
chroot "$CHROOT_TO" $cmd
exit_code="$?"

bldstat_clear "$status_is_chrooted"

env_cleanup

echo
# If there was an error in the chroot process, propagate it
exit "$exit_code"
