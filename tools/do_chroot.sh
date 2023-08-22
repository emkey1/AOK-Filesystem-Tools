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

#  Debug help, set to 1 to display entry and exit of functions
_fnc_calls=1

can_chroot_run_now() {
    [ "$_fnc_calls" = 1 ] && msg_2 "can_chroot_run_now()"

    [ ! -d "$CHROOT_TO" ] && error_msg "chroot destination does not exist: $CHROOT_TO"

    [ -z "$pidfile_do_chroot" ] && error_msg "pidfile_do_chroot is undefined!"
    if [ -f "$pidfile_do_chroot" ]; then
        # error_msg "pid exists"
        # Read the PID from the file
        pid=$(cat "$pidfile_do_chroot")

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
            echo "  $pidfile_do_chroot"
            echo
            echo "After this, request the environment to be cleaned up by running:"
            echo "$prog_name -c"
            exit 1
        fi
    fi
    [ "$_fnc_calls" = 1 ] && msg_3 "can_chroot_run_now() - done"
}

#
#  Since this is called via a parameterized trap, shellcheck doesnt
#  recognize this code is in use..
#
# shellcheck disable=SC2317  # Don't warn about unreachable code
cleanup() {
    [ "$_fnc_calls" = 1 ] && msg_2 "cleanup($1)"

    signal="$1" # this was triggered by trap
    case "$signal" in

    INT)
        echo "Ctrl+C (SIGINT) was caught."
        ;;

    TERM)
        echo "Termination (SIGTERM) was caught."
        ;;

    HUP)
        echo "Hangup (SIGHUP) was caught."
        ;;

    *)
        echo "Unknown signal ($signal) was caught."
        ;;

    esac

    env_restore
    [ "$_fnc_calls" = 1 ] && msg_3 "cleanup() - done"
}

ensure_dev_paths_are_defined() {
    #
    #  This ensures that all the system path variables have been defined,
    #  to minimize risk of having to abort half way through a procedure
    #
    [ "$_fnc_calls" = 1 ] && msg_2 "ensure_dev_paths_are_defined()"

    [ -z "$d_proc" ] && error_msg "d_proc undefined!"
    [ -z "$d_sys" ] && error_msg "d_sys undefined!"
    [ -z "$d_dev" ] && error_msg "d_dev undefined!"
    [ -z "$d_dev_pts" ] && error_msg "d_dev_pts undefined!"

    [ "$_fnc_calls" = 1 ] && msg_3 "ensure_dev_paths_are_defined() - done"
}

umount_mounted() {
    [ "$_fnc_calls" = 1 ] && msg_2 "umount_mounted($1)"
    # Only attempt unmount if it was mounted
    _mount_point="$1"

    if mount | grep -q "$_mount_point"; then
        umount "$_mount_point" || error_msg "Failed to unmount $_mount_point"
    else
        msg_3 "$_mount_point - was not mounted"
    fi
    cleanout_sys_dir "$_mount_point"

    [ "$_fnc_calls" = 1 ] && msg_3 "umount_mounted() - done"
}

cleanout_sys_dir() {
    [ "$_fnc_calls" = 1 ] && msg_2 "cleanout_sys_dir($1)"

    _d_clear="$1"
    [ -z "$_d_clear" ] && error_msg "cleanout_sys_dir() no param provided"
    [ ! -d "$_d_clear" ] && error_msg "cleanout_sys_dir($_d_clear) no such folder"

    if [ "$(find "$_d_clear"/ | wc -l)" -gt 1 ]; then
        msg_1 "Found residual files in: $_d_clear"
        ls -la "$_d_clear"
        echo "------------------"

        msg_3 "Removing residual files inside $_d_clear"
        rm -rf "${_d_clear:?}"/*
    fi
    [ "$_fnc_calls" = 1 ] && msg_3 "cleanout_sys_dir() - done"
}

set_chroot_to() {
    [ "$_fnc_calls" = 1 ] && msg_2 "set_chroot_to($1)"

    _chrt="$1"
    [ -z "$_chrt" ] && error_msg "set_chroot_to() no param"
    [ ! -d "$_chrt" ] && error_msg "set_chroot_to($_chrt) - path does not exist!"

    CHROOT_TO="$_chrt"
    #
    #  Must be called whenever CHROOT_TO is changed, like by param -p
    #
    d_proc="${CHROOT_TO}/proc"
    d_sys="${CHROOT_TO}/sys"
    d_dev="${CHROOT_TO}/dev"
    d_dev_pts="${CHROOT_TO}/dev/pts"
    [ "$_fnc_calls" = 1 ] && msg_3 "set_chroot_to() - done"
}

use_root_shell_as_default_cmd() {
    #
    #  Since no command was specified, try to extract the root
    #  shell from within the env. This to ensue we dont try
    #  to use a shell that is either not available, nor
    #  not found in the expeted location
    #
    [ "$_fnc_calls" = 1 ] && msg_2 "use_root_shell_as_default_cmd()"
    f_etc_pwd="${CHROOT_TO}/etc/passwd"
    [ ! -f "$f_etc_pwd" ] && error_msg "Trying to find chrooted root shell in its /etc/passwd failed"
    cmd_w_params="$(awk -F: '/^root:/ {print $NF" -l"}' "$f_etc_pwd")"
    [ "$_fnc_calls" = 1 ] && msg_3 "use_root_shell_as_default_cmd() - done"
}

env_prepare() {
    [ "$_fnc_calls" = 1 ] && msg_2 "env_prepare()"

    ensure_dev_paths_are_defined

    _err="$prog_name is running! - this should have already been caught!"
    [ -f "$pidfile_do_chroot" ] && error_msg "$_err"

    # msg_3 "creating pidfile_do_chroot: $pidfile_do_chroot"
    echo "$$" >"$pidfile_do_chroot"

    [ ! -d "$CHROOT_TO" ] && error_msg "chroot location [$CHROOT_TO] is not a directory!"

    # msg_3 "Mounting system resources"

    if mount | grep -q "$CHROOT_TO"; then
        error_msg "This [$CHROOT_TO] is already chrooted!"
    fi

    [ ! -d "$d_proc" ] && error_msg "Directory $d_proc is missing"
    mount -t proc proc "$d_proc"

    if [ "$build_env" -eq 1 ]; then
        # msg_3 "Setting up needed /dev items"

        mknod "$CHROOT_TO"/dev/null c 1 3
        chmod 666 "$CHROOT_TO"/dev/null

        mknod "$CHROOT_TO"/dev/urandom c 1 9
        chmod 666 "$CHROOT_TO"/dev/urandom

        mknod "$CHROOT_TO"/dev/zero c 1 5
        chmod 666 "$CHROOT_TO"/dev/zero
    else
        [ ! -d "$d_sys" ] && error_msg "Directory $d_sys is missing"
        [ ! -d "$d_dev" ] && error_msg "Directory $d_dev is missing"

        mount -t sysfs sys "$d_sys"
        mount -o bind /dev "$d_dev"
        #
        #  $d_dev_pts wont exist until d_dev is mounted, so cant be
        #  checked in advance, and if we can mount d_dev without error
        #  it is highly unlikely to be an issue
        #
        mount -o bind /dev/pts "$d_dev_pts"
    fi
    # msg_3 "copying current /etc/resolv.conf"
    cp /etc/resolv.conf "$CHROOT_TO/etc"

    [ "$_fnc_calls" = 1 ] && msg_3 "env_prepare() - done"
}

#  shellcheck disable=SC2120
env_restore() {
    if [ "$_fnc_calls" = 1 ]; then
        if [ -n "$env_restore_started" ]; then
            msg_1 "env_restore() has already been called, skipping"
            return
        fi
        msg_2 "env_restore()"
    else
        [ -n "$env_restore_started" ] && return
    fi
    env_restore_started=1

    ensure_dev_paths_are_defined

    #
    #  This would normally be called as a mount session is terminating
    #  so therefore the pidfile_do_chroot should not be checked.
    #  Assume that if we get here we can do the cleanup.
    #

    [ -z "$d_proc" ] && error_msg "variable d_proc is undefiened"
    [ ! -d "$d_proc" ] && error_msg "Directory $d_proc is missing"

    msg_3 "Un-mounting system resources"
    umount_mounted "$d_proc"

    umount_mounted "$d_sys"
    cleanout_sys_dir "$d_sys"

    umount_mounted "$d_dev_pts"
    umount_mounted "$d_dev"
    cleanout_sys_dir "$d_dev"

    #
    #  Complain about pottenially bad pidfile_do_chroot after completing the procedure
    #
    [ -z "$pidfile_do_chroot" ] && error_msg "pidfile_do_chroot is undefined!"

    [ -n "$pidfile_do_chroot" ] && {
        # msg_3 "removing pidfile_do_chroot: $pidfile_do_chroot"
        rm -f "$pidfile_do_chroot"
    }

    [ "$_fnc_calls" = 1 ] && msg_3 "env_restore() - done"
}

show_help() {
    # msg_2 "show_help()"

    cat <<EOF
Usage: $prog_name [-h] [-a] [-c] [-C] [-p dir] [command]

Available options:

-h  --help      Print this help and exit
-a  --available Reports if this can be run now
-c  --cleanup   Cleanup env if something crashed whilst sudoed
-p, --path      What dir to chroot into, defaults to: $build_root_d
command         Defaults to the shell used by root within the env

chroot with env setup so this works on both Linux & iSH

Normally this will clear up the env even if the chroot crashes.
If it does  fail to clean up, and you attempt to run with -c
used -p to chroot to a custom path, you must take care to give
-p BEFORE -c in order for this to know what reminant mount points to
clean up!

EOF

    # msg_3 "show_help() - done"
}

chroot_statuses() {
    #
    #  This is mostly a debug helper, so only informative
    #  does not contribute to the actual process
    #
    [ "$_fnc_calls" = 1 ] && msg_2 "chroot_statuses($1)"

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
    [ "$_fnc_calls" = 1 ] && msg_3 "chroot_statuses() - done"
}

#===============================================================
#
#   Main
#
#===============================================================

prog_name="$(basename "$0")"

#  Allowing this to be run from anywhere using path
current_dir=$(cd -- "$(dirname -- "$0")" && pwd)
AOK_DIR="$(dirname -- "$current_dir")"

#
#  Automatic sudo if run by a user account, do this before
#  sourcing tools/utils.sh !!
#
# shellcheck source=/opt/AOK/tools/run_as_root.sh
hide_run_as_root=1 . "$AOK_DIR/tools/run_as_root.sh"

# shellcheck source=/opt/AOK/tools/utils.sh
. "$AOK_DIR"/tools/utils.sh

set_chroot_to "$build_root_d"

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
        set_chroot_to "$2"
        shift # get rid of the option
        shift # get rid of the dir
    else
        error_msg "-p assumes a param pointing to where to chroot!"
    fi
    ;;

"-c" | "--cleanup")
    echo
    echo "Please be aware that if you attempt to clean up after a chroot"
    echo "to a non-standard path (ie you used -p), you must use this notation"
    echo "in order to attempt to clean up the right things."
    echo
    echo "$prog_name -p /custom/path -c"
    echo
    echo "This will continue in 5 secnods, hit Ctrl-C if you want to abort"
    sleep 5

    can_chroot_run_now
    env_restore
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

#error_msg "abort after checking for existance"

#
#  In case something fails, always try to unmount
#
trap 'cleanup INT' INT
trap 'cleanup TERM' TERM

env_prepare

[ -z "$build_root_d" ] && error_msg "build_root_d empty!" 1

if [ "$1" = "" ]; then
    use_root_shell_as_default_cmd
else
    cmd_w_params="$*"
    _cmd="$1"
    if [ "${_cmd%"${_cmd#?}"}" = "/" ]; then
        #
        #  State of requested command cant really be examined without
        #  a full path
        #
        if ! [ -f "${build_root_d}${_cmd}" ]; then
            msg_1 "Might not work, file not found: ${build_root_d}${_cmd}"
        elif ! [ -x "${build_root_d}${_cmd}" ]; then
            msg_1 "Might not work, file not executable: ${build_root_d}${_cmd}"
        fi
    fi
fi

msg_1 "chrooting: $CHROOT_TO ($cmd_w_params)"

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
    echo ">> about to run: chroot $CHROOT_TO $cmd_w_params"
fi

#
#  Here we must disable all env variables that should not be passed into
#  the chroot env, like TMPDIR
#
#  In this case we want the $cmd_w_params variable to expand into its components
#  shellcheck disable=SC2086
TMPDIR="" chroot "$CHROOT_TO" $cmd_w_params
exit_code="$?"

[ -n "$DEBUG_BUILD" ] && msg_1 "----------  back from chroot  ----------"

env_restore

destfs_clear_chrooted

# If there was an error in the chroot process, propagate it
exit "$exit_code"
