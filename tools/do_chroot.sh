#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023-2024: Jacob.Lundqvist@gmail.com
#
#  Tries to ensure a successful chroot both on native iSH and on Linux (x86)
#  by allocating and freeing OS resources needed.
#  Since during the deploy kernel features are checked for, services might
#  be probed or even started, it is necesery to have various system dirs
#  mounted during deploy.
#  If the chroot starts a service or other sub process that opes a file
#  to one of the sys dirs, for instance writes to /dev/null
#  This prevents the chrooted /dev from being unmounted, so during
#  restore of the env there is a scan for any processes blocking
#  unmounting, and an attempt to kill them is done.
#
#  Since this is a POSIX script, there are no local variables,
#  to minimize risk of unintentionally changing an outer variable
#  many functions where variables are of a temporary natue  use
#  variable names of the form:   _ + shorthand for func name
#

# Global exclude
# shellcheck disable=SC2317

#
#  Debug help, set to 1 to display entry  of functions
#  set to 2 to also display exits
#
_fnc_calls=0

show_help() {
    # msg_2 "show_help()"

    #region help text
    echo "
Usage: $prog_name [-h] [-c] [-p dir] [-f] [command]

Available options:

-h  --help      Print this help and exit
-c  --cleanup   Cleanup env if something crashed whilst sudoed
-f, --force     Run this despite a warning indicating it will likely
                not work.
-p, --path      What dir to chroot into, defaults to: $d_build_root

command         Defaults to the shell used by root within the env

chroot with env setup so this works on both Linux & iSH

Normally this will clear up the env even if the chroot crashes.
If it does  fail to clean up, and a custom path was used.
-p must be given BEFORE -c in order for this to know what mount point
to clean up!

"
    #endregion
    # msg_3 "show_help() - done"
}

can_chroot_run_now() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "can_chroot_run_now()"

    display_cleanup_procedure=false

    define_chroot_env

    [ ! -d "$CHROOT_TO" ] && error_msg "chroot destination does not exist: $CHROOT_TO"

    if [ -f "$f_is_chrooted" ]; then
        echo "$CHROOT_TO is already chrooted!"
        echo
        echo "If the system crashed as a chroot was active, this situation"
        echo "would not be unlikely."
        display_cleanup_procedure=true
    else
        set_ch_procs
        if [ -n "$ch_procs" ]; then
            echo "There are left-over processes from a previous run of this chroot"
            echo "processes: $ch_procs"
            display_cleanup_procedure=true
        # else
        #     unmount_systen_folders
        fi
    fi

    $display_cleanup_procedure && {
        echo
        echo "This chroot and all its processes can be cleaned up by running:"
        if [ "$CHROOT_TO" = "$d_build_root" ]; then
            echo "$cmd_line -c"
        else
            echo "$cmd_line -p $CHROOT_TO -c"
        fi
        echo
        exit 1
    }

    [ "$_fnc_calls" = 2 ] && msg_3 "can_chroot_run_now() - done"
}

defined_and_existing() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "defined_and_existing($1)"

    _dae="$1"
    [ -z "$_dae" ] && error_msg "defined_and_existing() no param provided"
    [ ! -d "$_dae" ] && error_msg "defined_and_existing($_dae) no such folder"
    unset _dae

    [ "$_fnc_calls" = 2 ] && msg_3 "defined_and_existing($1) - done"
}

ensure_dev_paths_are_defined() {
    #
    #  This ensures that all the system path variables have been defined,
    #  to minimize risk of having to abort half way through a procedure
    #
    [ "$_fnc_calls" -gt 0 ] && msg_2 "ensure_dev_paths_are_defined($1)"

    defined_and_existing "$CHROOT_TO"
    defined_and_existing "$d_proc"
    defined_and_existing "$d_dev"
    if [ "$build_env" = "$be_linux" ]; then
        defined_and_existing "$d_sys"
        if [ "$1" = "skip_pts" ]; then
            #
            #  Before mounting the resources dev/pts will not exist, so
            #  preparational checks will need to handle /dev/pts as a special case.
            #  At that point all that can be done is to verify that it has been set
            #
            [ -z "$d_dev_pts" ] && error_msg "ensure_dev_paths_are_defined() - d_dev_pts undefined"
        else
            defined_and_existing "$d_dev_pts"
        fi
    fi

    [ "$_fnc_calls" = 2 ] && msg_3 "ensure_dev_paths_are_defined($1) - done"
}

define_chroot_env() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "define_chroot_env()"

    [ -z "$CHROOT_TO" ] && error_msg "define_chroot_env() CHROOT_TO not defined!"
    [ ! -d "$CHROOT_TO" ] && error_msg "define_chroot_env() - path does not exist: $CHROOT_TO"

    f_is_chrooted="${CHROOT_TO}$f_host_fs_is_chrooted"

    #
    #  Must be called whenever CHROOT_TO is changed, like by param -p
    #
    d_proc="${CHROOT_TO}/proc" #; exists_and_empty "$d_proc"
    d_dev="${CHROOT_TO}/dev"   #; exists_and_empty "$d_dev"

    if [ "$build_env" = "$be_linux" ]; then
        d_sys="${CHROOT_TO}/sys" #   ; exists_and_empty "$d_sys"
        d_dev_pts="${CHROOT_TO}/dev/pts"
    fi
    ensure_dev_paths_are_defined "skip_pts"

    [ "$_fnc_calls" = 2 ] && msg_3 "define_chroot_env() - done"
}

find_default_cmd() {
    #
    #  Since no command was specified, first check if this
    #  chroot has a defined default command in /.chroot_default_cmd
    #  If this is not found, try to login as root with root's shell.
    #  This to ensue we dont try to use a shell that is either not
    #  available, or not found in the expeted location
    #
    [ "$_fnc_calls" -gt 0 ] && msg_2 "find_default_cmd()"
    _f="${CHROOT_TO}/.chroot_default_cmd"
    if [ -f "$_f" ]; then
        cmd_w_params="$(cat "$_f")"
        [ "$_fnc_calls" -gt 0 ] && msg_3 "Found a default cmd: $cmd_w_params"
    else
        [ "$_fnc_calls" -gt 0 ] && msg_2 "Trying to use root shell as default cmd"
        _f="${CHROOT_TO}/etc/passwd"
        [ ! -f "$_f" ] && error_msg "Trying to find chrooted root shell in its /etc/passwd failed"
        cmd_w_params="$(awk -F: '/^root:/ {print $NF" -l"}' "$_f")"
        [ "$_fnc_calls" -gt 0 ] && msg_3 "use_root_shell_as_default_cmd() - done"
    fi
    [ "$_fnc_calls" = 2 ] && msg_3 "find_default_cmd()"
}

#use_root_shell_as_default_cmd
env_prepare() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "env_prepare()"

    ensure_dev_paths_are_defined "skip_pts"

    _err="$prog_name is running! - this should have already been caught!"
    [ -f "$f_is_chrooted" ] && error_msg "$_err"
    unset _err

    [ ! -d "$CHROOT_TO" ] && error_msg "chroot location [$CHROOT_TO] is not a directory!"

    msg_3 "Mounting system resources"

    mount -t proc proc "$d_proc"

    if [ "$build_env" = "$be_ish" ]; then
        #
        #  I havent figured out how to mount /dev on iSH for the
        #  chrooted env, so for now, I simply copy the host /dev files
        #  into the chroot env. And remove them when exiting
        #
        cp -a /dev/* "$d_dev"
    elif [ "$build_env" = "$be_linux" ]; then
        #	mount -t sysfs sys "$d_sys"
        mount -o bind /dev "$d_dev"
        mount -o bind /dev/pts "$d_dev_pts"
    fi

    # msg_3 "copying current /etc/resolv.conf"
    cp /etc/resolv.conf "$CHROOT_TO/etc"

    [ "$_fnc_calls" = 2 ] && msg_3 "env_prepare() - done"
}

exists_and_empty() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "exists_and_empty($1)"

    _eae="$1"
    defined_and_existing "$_eae"
    [ "$(find "$_eae" | wc -l)" -gt 1 ] && error_msg "exists_and_empty($_eae) -Not empty"
    unset _eae

    [ "$_fnc_calls" = 2 ] && msg_3 "exists_and_empty($1) - done"
}

#  shellcheck disable=SC2120
set_ch_procs() {
    #
    # Since this is used in multiple places, use a func to ensure same
    # filtering is done
    #

    if hostfs_is_alpine; then
        ch_procs="$(lsof 2>/dev/null | grep "$CHROOT_TO" |
            awk '{print $1 }' | sort | uniq | tr '\n' ' ')"
    else
        ch_procs="$(lsof 2>/dev/null | grep "$CHROOT_TO" |
            awk '{print $2 }' | sort | uniq | tr '\n' ' ')"
    fi
}

kill_remaining_procs() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "kill_remaining_procs()"

    # msg_3 "Ensuring chroot env didn't leave any process running..."

    set_ch_procs
    [ -z "$ch_procs" ] && return # nothing needs killing

    msg_3 "remaining procs to kill: [$ch_procs]"
    echo "$ch_procs" | tr ' ' '\n' | xargs kill -9
    # shell check disable=SC2016,SC2086  # TODO: fix and test
    # echo $ch_procs | tr ' ' '\n' | xargs -I {} sh -c 's="$(ps ax|grep {} |grep -v grep)" ;echo  "attempting to kill: $s" ; kill {}'

    #
    #  Ensure thee are no leftovers that kill didnt get rid off
    #
    msg_3 "Making sure no processes remains"
    set_ch_procs
    if [ -n "$ch_procs" ]; then
        msg_1 "***  WARNING - remaining procs: [$ch_procs]  ***"

        echo "Remaining mounts:"
        echo

        mount | grep "$CHROOT_TO"

        echo
        echo "Must be manually unmouunted once offending process are gone"
        echo
        exit 1
    fi

    [ "$_fnc_calls" = 2 ] && msg_3 "kill_remaining_procs() - done"
}

cleanout_dir() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "cleanout_dir($1)"

    d_clear="$1"
    [ -z "$d_clear" ] && error_msg "cleanout_dir() no param provided"

    if [ -n "${d_clear##"$CHROOT_TO"*}" ]; then
        error_msg "cleanout_dir($d_clear) not part of chroot point! [$CHROOT_TO]"
    elif [ "$d_clear" = "$CHROOT_TO" ]; then
        error_msg "cleanout_dir($d_clear) is chroot point!"
    fi

    if [ "$(find "$d_clear"/ 2>/dev/null | wc -l)" -gt 1 ]; then
        msg_1 "Found residual files in: $d_clear"
        ls -la "$d_clear"
        echo "------------------"

        msg_3 "Removing residual files inside $d_clear"
        rm -rf "${d_clear:?}"/*
    fi
    unset d_clear

    [ "$_fnc_calls" = 2 ] && msg_3 "cleanout_dir($1) - done"
}

umount_mounted() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "umount_mounted($1)"

    _um="$1"
    if mount | grep -q "$_um"; then
        $show_unmounts && msg_3 "unmounting $_um"
        umount "$_um" || error_msg "Failed to unmount $_um"
    fi

    cleanout_dir "$_um"
    unset _um

    [ "$_fnc_calls" = 2 ] && msg_3 "umount_mounted($1) - done"
}

unmount_systen_folders() {
    umount_mounted "$d_proc"
    if [ "$build_env" = "$be_ish" ]; then
        rm -rf "${d_dev:?}"/*
        #  ensure it is empty
        cleanout_dir "$d_dev"
    elif [ "$build_env" = "$be_linux" ]; then
        umount_mounted "$d_sys"
        umount_mounted "$d_dev_pts"
        umount_mounted "$d_dev"
    fi
}

env_restore() {
    #
    #  This would normally be called as a mount session is terminating
    #  Assume that if we get here we can do the cleanup.
    #
    if [ -n "$env_restore_started" ]; then
        msg_1 "env_restore() has already been called, skipping"
        return
    fi
    [ "$_fnc_calls" -gt 0 ] && msg_2 "env_restore()"

    env_restore_started=1
    ensure_dev_paths_are_defined skip_pts

    msg_2 "Releasing system resources"
    kill_remaining_procs

    $show_unmounts && {
        # in cleanup mode, once all related processes are killed
        # the unmounts are done by the previous chroot, so give this
        # some time to happen
        sleep 2
    }

    unmount_systen_folders

    [ "$_fnc_calls" = 2 ] && msg_3 "env_restore() - done"
}

#
#  Since this is called via a parameterized trap, shellcheck doesnt
#  recognize this code is in use..
#
# shellcheck disable=SC2317  # Don't warn about unreachable code
cleanup() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "cleanup($1)"

    _signal="$1" # this was triggered by trap
    case "$_signal" in

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
        echo "Unknown signal ($_signal) was caught."
        ;;

    esac
    unset _signal

    env_restore
    [ "$_fnc_calls" = 2 ] && msg_3 "cleanup($1) - done"
}

#===============================================================
#
#   Main
#
#===============================================================

#
#  needed during cleanup to filter out processes with
#  SUDO_COMMAND=$cmd_line
#
cmd_line="$0"
prog_name="$(basename "$cmd_line")"

hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
[ -z "$d_aok_etc" ] && . /opt/AOK/tools/utils.sh

CHROOT_TO="$d_build_root" # default opt -p overrides
show_unmounts=false

if [ "$build_env" = "$be_other" ]; then
    echo
    echo "AOK can only be chrooted on iSH or Linux (x86)"
    echo
    exit 1
fi

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else, this to ensure build_env can be found
#
cd /opt/AOK || {
    error_msg "Failed to cd into: /opt/AOK"
}

while [ -n "$1" ]; do

    firstchar="$(echo "$1" | cut -c1-1)"
    if [ "$firstchar" != "-" ]; then
        #  No more options, continue
        break
    fi

    case "$1" in

    "-h" | "--help")
        show_help
        exit 0
        ;;

    "-c" | "--cleanup")
        show_unmounts=true
        cleanup_sleep=2
        #region cleanup explaination
        echo "

Will cleanup the mount point: $CHROOT_TO

Please be aware that if an attempt is made to clean up after a chroot to a
non-standard path with -p, this notation must be used in order to attempt
to clean up the right things.

$cmd_line -p /custom/path -c

This will continue in $cleanup_sleep secnods,hit Ctrl-C if you want to abort
"
        #endregion
        sleep "$cleanup_sleep"

        define_chroot_env
        env_restore
        exit 0
        ;;

    "-f" | "--force")
        msg_1 "Using force!"
        force_this=1
        ;;

    "-p" | "--path")
        if [ -d "$2" ]; then
            CHROOT_TO="$2"
            shift # get rid of the dir
        else
            error_msg "-p assumes a param pointing to where to chroot!"
        fi
        ;;

    *)
        error_msg "invalid option! Try using: -h"
        ;;

    esac
    shift
done

if this_is_ish && hostfs_is_debian && [ "$force_this" != "1" ]; then
    echo "************"
    echo "ish running Debian - this does not seem able to do chroot. You have been warned..."
    echo "                     Run this with -f if you still want to go ahead"
    echo "************"
    exit 1
fi

define_chroot_env
can_chroot_run_now

#
#  In case something fails, always try to unmount
#
trap 'cleanup INT' INT
trap 'cleanup TERM' TERM

[ -z "$d_build_root" ] && error_msg "d_build_root empty!" 1

if [ "$1" = "" ]; then
    find_default_cmd
    if [ -z "$cmd_w_params" ]; then
        error_msg "Could not find any default command, you must supply one"
    fi
else
    cmd_w_params="$*"
    _cmd="$1"
    if [ "${_cmd%"${_cmd#?}"}" = "/" ]; then
        #
        #  State of requested command cant really be examined without
        #  a full path
        #
        if ! [ -f "${d_build_root}${_cmd}" ]; then
            msg_1 "Might not work, file not found: ${d_build_root}${_cmd}"
        elif ! [ -x "${d_build_root}${_cmd}" ]; then
            msg_1 "Might not work, file not executable: ${d_build_root}${_cmd}"
        fi
    fi
fi

env_prepare

msg_1 "chrooting: $CHROOT_TO ($cmd_w_params)"

mkdir -p "$(dirname "$f_is_chrooted")"
touch "$f_is_chrooted"

#
#  Here we must disable all env variables that should not be passed into
#  the chroot env, like TMPDIR
#
#  In this case we want the $cmd_w_params variable to expand into its components
#  shellcheck disable=SC2086
TMPDIR="" SHELL="" LANG="" chroot "$CHROOT_TO" $cmd_w_params
chroot_exit_code="$?"

rm -f "$f_is_chrooted"

# else
#     msg_2 "Clearing alt chroot flag: [$f_is_chrooted]"
#     rm "$f_is_chrooted"
# fi

env_restore

# If there was an error in the chroot process, propagate it
exit "$chroot_exit_code"
