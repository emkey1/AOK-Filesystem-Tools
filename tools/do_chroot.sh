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

can_chroot_run_now() {
    # msg_2 "can_chroot_run_now()"

    [ -z "$pid_file" ] && error_msg "pid_file is undefined!"
    if [ -f "$pid_file" ]; then
        # error_msg "pid exists"
        # Read the PID from the file
        pid=$(cat "$pid_file")

        # Check if the process is still running
        if ps -p "$pid" >/dev/null 2>&1; then
            error_msg "$prog_name with PID $pid is running!"
        else
            msg_1 "There is no process with PID $pid running."

            echo "If the system crashed as a chroot was active, this situation"
            echo "would not be unlikely."
            echo
            echo "If you are certain that there is no ongoing chroot task,"
            echo "you can delete the below PID file"
            echo "  $pid_file"
            echo
            echo "After this, request the environment to be cleaned up by running:"
            echo "$prog_name -c"
            exit 1
        fi
    fi
    # msg_3 "can_chroot_run_now() - done"
}

use_root_shell_as_default_cmd() {
    #
    #  Since no command was specified, try to extract the root
    #  shell from within the env. This to ensue we dont try
    #  to use a shell that is either not available, nor
    #  not found in the expeted location
    #
    # msg_2 "use_root_shell_as_default_cmd()"

    f_etc_pwd="$CHROOT_TO/etc/passwd"
    [ ! -f "$f_etc_pwd" ] && error_msg "Trying to find chrooted root shell in its /etc/passwd failed"

    cmd="$(awk -F: '/^root:/ {print $NF" -l"}' "$f_etc_pwd")"

    # msg_3 "use_root_shell_as_default_cmd() - done"
}

env_prepare() {
    # msg_2 "env_prepare()"

    #  To ensure nothing bad happens it doesnt hurt to run this multipple times
    can_chroot_run_now

    _err="$prog_name is running! - this should have already been caught!"
    [ -f "$pid_file" ] && error_msg "$_err"

    # msg_3 "creating pid_file: $pid_file"
    echo "$$" >"$pid_file"

    [ ! -d "$CHROOT_TO" ] && error_msg "chroot location [$CHROOT_TO] is not a directory!"

    # msg_3 "Mounting system resources"

    if mount | grep -q "$CHROOT_TO"; then
        error_msg "This [$CHROOT_TO] is already chrooted!"
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

    # msg_3 "env_prepare() - done"
}

env_cleanup() {
    # msg_2 "env_cleanup()"

    #
    #  This would normally be called as a mount session is terminating
    #  so therefore the pid_file should not be checked.
    #  Assume that if we get here we can do the cleanup.
    #

    # msg_3 "Un-mounting system resources"
    umount "$CHROOT_TO"/proc || return 1

    if [ "$build_env" -eq 1 ]; then
        # msg_3 "Removing the temp /dev entries"
        rm -rf "${CHROOT_TO:?}"/dev/*
    else
        # msg_3 "Unmounting /sys & /dev"
        umount "$CHROOT_TO"/sys || return 1
        umount "$CHROOT_TO"/dev/pts || return 1
        umount "$CHROOT_TO"/dev || return 1
    fi

    #
    #  Complain about pottenially bad pid_file after completing the procedure
    #
    [ -z "$pid_file" ] && error_msg "pid_file is undefined!"

    [ -n "$pid_file" ] && {
        # msg_3 "removing pid_file: $pid_file"
        rm -f "$pid_file"
    }

    # msg_3 "env_cleanup() - done"
}

show_help() {
    # msg_2 "show_help()"

    cat <<EOF
Usage: $prog_name [-h] [-a] [-c] [-C] [-p dir] [command]

chroot with env setup so this works on both Linux & iSH

Available options:

-h  --help      Print this help and exit
-a  --available Reports if this can be run now
-c  --cleanup   Cleanup env if something crashed whilst sudoed
-p, --path      What dir to chroot into, defaults to: $build_root_d
command         Defaults to the shell used by root within the env
EOF

    # msg_3 "show_help() - done"
}

chroot_statuses() {
    #
    #  This is mostly a debug helper, so only informative
    #  does not contribute to the actual process
    #
    # msg_2 "chroot_statuses()"

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
    # msg_3 "chroot_statuses() - done"
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
hide_run_as_root=1 . "$current_dir"/run_as_root.sh

# shellcheck source=/opt/AOK/tools/utils.sh
. "$current_dir"/utils.sh

pid_file="$TMPDIR/aok_do_chroot.pid"
prog_name="$(basename "$0")"
CHROOT_TO="$build_root_d"

if this_is_ish && hostfs_is_debian; then
    echo "************"
    echo "ish running Debian - this does not seem able to do chroot. You have been warned..."
    echo "************"
fi

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

"-a" | "--available")
    can_chroot_run_now
    msg_1 "$prog_name not running, can be started!"
    #
    #  This check should already have exited, exit busy, now in case
    #  something went wrong
    #
    exit 1
    ;;

"-p" | "--path")
    if [ -d "$2" ]; then
        CHROOT_TO="$2"
        shift # get rid of the option
        shift # get rid of the dir
    else
        error_msg "-p assumes a param pointing to where to chroot!"
    fi
    ;;

"-c" | "--cleanup")
    can_chroot_run_now
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

can_chroot_run_now

#
#  In case something fails, always try to unmount
#
trap env_cleanup EXIT

env_prepare

[ -z "$build_root_d" ] && error_msg "build_root_d empty!" 1

if [ "$1" = "" ]; then
    use_root_shell_as_default_cmd
else
    cmd="$*"
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

# If there was an error in the chroot process, propagate it
exit "$exit_code"
