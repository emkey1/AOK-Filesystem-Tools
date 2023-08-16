#!/bin/sh
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

env_prepare() {
    # msg_2 "Preparing the environment for chroot"

    # msg_3 "Mounting system resources"

    if mount | grep -q "$CHROOT_TO"; then
        error_msg "This is already chrooted!"
    fi

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
        mount -o bind /dev/pts "$CHROOT_TO"/dev/pts
    fi
    # msg_3 "copying current /etc/resolv.conf"
    cp /etc/resolv.conf "$CHROOT_TO/etc"
}

env_cleanup() {
    msg_2 "Doing some post chroot cleanup"

    # msg_3 "Un-mounting system resources"
    umount "$CHROOT_TO"/proc || return 1

    if [ "$build_env" -eq 1 ]; then
        msg_3 "Removing the temp /dev entries"
        rm -rf "${CHROOT_TO:?}"/dev/*
    else
        msg_3 "Unmounting /sys & /dev"
        umount "$CHROOT_TO"/sys || return 1
        umount "$CHROOT_TO"/dev/pts || return 1
        umount "$CHROOT_TO"/dev || return 1
    fi
}

show_help() {
    cat <<EOF
Usage: $prog_name [-h] | [-v] | [-c] | [-p dir] command

chroot with env setup so this works on both Linux & iSH

Available options:

-h  --help     Print this help and exit
-c  --cleanup  Cleanup env if something crashed whilst sudoed
-C  --clear    First do a --cleanup, then remove the build_root ($build_root_d)
-p, --path     What dir to chroot into, defaults to: $build_root_d
command        What to run, defaults to "bash -l", command and params must be quoted!
EOF

}

chroot_statuses() {
    [ -n "$1" ] && msg_1 "chroot_statuses - $1"

    msg_2 "Displaying chroot statuses"
    if this_fs_is_chrooted; then
        msg_1 "Host IS"
    else
        msg_3 "Host not"
    fi
    if dest_fs_is_chrooted; then
        msg_3 "Dest is (not yet, but flagged as such)"
    else
        msg_3 "Dest not"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

#  Allowing this to be run from anywhere using path
current_dir=$(cd -- "$(dirname -- "$0")" && pwd)

#
#  Automatic sudo if run by a user account, do this before
#  sourcing tools/utils.sh !!
#
# shellcheck source=/opt/AOK/tools/run_as_root.sh
. "$current_dir"/run_as_root.sh

# shellcheck source=/opt/AOK/tools/utils.sh
. "$current_dir"/utils.sh

if this_is_ish && hostfs_is_debian; then
    echo "************"
    echo "ish running Debian - this does not seem able to do chroot. You have been warned..."
    echo "************"
fi

prog_name="$(basename "$0")"

CHROOT_TO="$build_root_d"

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
cd "$aok_content" || {
    error_msg "Failed to cd into: $aok_content"
}

# if [ "$(whoami)" != "root" ]; then
#     error_msg "This must be run as root or using sudo!"
# fi

case "$1" in

"-h" | "--help")
    show_help
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

"-C" | "--clear")
    [ -z "$build_root_d" ] && error_msg "build_root_d empty!" 1

    if [ -z "$build_root_d" ]; then
        error_msg "build_root_d undefined, cant clear build env" 1
    fi

    if ! env_cleanup; then
        msg_1 "cleanup failed!"
    fi

    clr_timeout=2
    msg_1 "Will clear [$build_root_d] in $clr_timeout seconds..."
    sleep "$clr_timeout"
    rm -rf "$build_root_d"
    [ -e "$build_root_d" ] && error_msg "Failed to clear: $build_root_d"
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

[ -z "$build_root_d" ] && error_msg "build_root_d empty!" 1

if [ "$1" = "" ]; then
    cmd="/usr/bin/env bash -l"
else
    cmd="$1"
    if ! [ -f "${build_root_d}${cmd}" ]; then
        msg_1 "Might not work, cmd not found: ${build_root_d}${cmd}"
    fi
fi

msg_1 "chrooting: $CHROOT_TO ($cmd)"

if [ -n "$DEBUG_BUILD" ]; then
    msg_2 "Deploy state: $(deploy_state_get)"
    msg_2 "chroot statuses before"
    chroot_statuses "Before setting destfs"
fi

destfs_set_is_chrooted

if [ -n "$DEBUG_BUILD" ]; then
    chroot_statuses "After setting destfs"
    msg_2 "build_root_d [$build_root_d]"
    msg_3 "Detected: [$(destfs_detect)]"
    echo
    echo ">>> -----  displaying host fs status"
    find /etc/opt
    echo ">>> -----"
    echo
    echo ">>> -----  displaying dest fs status"
    find "$build_root_d"/etc/opt
    echo ">>> -----"
    echo
    msg_1 "==========  doing chroot  =========="
    echo ">> about to run: chroot $CHROOT_TO $cmd"
fi

#  In this case we want the $cmd variable to expand into its components
#  shellcheck disable=SC2086
chroot "$CHROOT_TO" $cmd
exit_code="$?"

[ -n "$DEBUG_BUILD" ] && msg_1 "----------  back from chroot  ----------"

destfs_clear_chrooted

env_cleanup

echo
# If there was an error in the chroot process, propagate it
exit "$exit_code"
