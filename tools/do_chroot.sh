#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
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

can_chroot_run_now() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "can_chroot_run_now()"

    [ -z "$pidfile_do_chroot" ] && error_msg "pidfile_do_chroot is undefined!"
    [ ! -d "$CHROOT_TO" ] && error_msg "chroot destination does not exist: $CHROOT_TO"

    if [ -f "$pidfile_do_chroot" ]; then
        # Read the PID from the file
        _pid=$(cat "$pidfile_do_chroot")

        # Check if the process is still running
        if ps -p "$_pid" >/dev/null 2>&1; then
            error_msg "$prog_name with PID $_pid is running!"
        else
            msg_1 "There is no process with PID $_pid running."

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
    unset _pid

    #
    #  Last check, ensure no sys dirs are mounted already at this location
    #  That would strongly indicate a concurrent chroot
    #
    if [ -n "$(lsof |grep "$CHROOT_TO")" ]; then
        echo "ERROR: Active chroot session detected at $CHROOT_TO!"
        echo "       If this is due to a crash or abort, you can clear it by running:"
        echo "         tools/do_chroot.sh -c"
        echo
        exit 1
    fi

    [ "$_fnc_calls" = 2 ] && msg_3 "can_chroot_run_now() - done"
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

exists_and_empty() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "exists_and_empty($1)"

    _eae="$1"
    defined_and_existing "$_eae"
    [ "$(find "$_eae" | wc -l)" -gt 1 ] && error_msg "exists_and_empty($_eae) -Not empty"
    unset _eae

    [ "$_fnc_calls" = 2 ] && msg_3 "exists_and_empty($1) - done"
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

set_ch_procs() {
    # Since this is done twice, use a func to ensure same filtering is done

    #
    #  needed so that we can filter chroot processes having the real
    #  SUDO_COMMAND in their env. Without this the child ps, grep & awk
    #  processes would inherit the env variable created by the chroot.
    #
    #  For some reason, despite this the process running this script
    #  maintains the env setting SUDO_COMMAND set by chroot,
    #  so that process has to be filtered out by grep -v " $cmd_line"
    #  pretty much a cludge, but the best I could come up with so far
    #
    #  Be aware that this wont catch procs that on purpose clear
    #  or edit their SUDO_COMMAND env variable
    #
    export SUDO_COMMAND=none

    if hostfs_is_alpine; then
	#
	#  Be aware that sometimes calling lsof will cause iSH-AOK
	#  to crash hard
	#
	_procs="$(lsof |grep aok_fs | awk '{print $1}' | uniq  | tr '\n' ' ')"
    else
	_procs="$(ps axe |grep SUDO_COMMAND=$cmd_line | \
 	          grep -v " $cmd_line" | grep -v SUDO_COMMAND=none | \
		  awk '{print $1 }' | tr '\n' ' ')"
    fi

    # Trim trailing whitespace
    ch_procs="${_procs%"${_procs##*[![:space:]]}"}"
    unset _procs
}

kill_remaining_procs() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "kill_remaining_procs()"

    msg_3 "Ensuring chroot env didn't leave any process running..."

    set_ch_procs
    [ -z "$ch_procs" ] && return  # nothing needs killing

    msg_3 "remaining procs to kill: [$ch_procs]"
    echo $ch_procs | tr ' ' '\n' | xargs -I {} sh -c 's="$(ps ax|grep {} |grep -v grep)" ;echo  "attempting to kill: $s" ; kill {}'

    #
    #  Ensure thee are no leftovers that kill didnt get rid off
    #
    msg_3 "Making sure nothing remains"
    set_ch_procs
    if [ -n "$ch_procs" ]; then
	msg_3 "***  WARNING - remaining procs: [$ch_procs]  ***"

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

umount_mounted() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "umount_mounted($1)"

    _um="$1"

    if mount | grep -q "$_um"; then
	defined_and_existing "$_um"
        umount "$_um" || error_msg "Failed to unmount $_um"
	[ -d "$_um" ] && cleanout_dir "$_um"
    else
        #msg_3 "$_um - was not mounted"
	cleanout_dir "$_um"
    fi
    unset _um

    [ "$_fnc_calls" = 2 ] && msg_3 "umount_mounted($1) - done"
}

define_chroot_env() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "define_chroot_env()"

    [ -z "$CHROOT_TO" ] && error_msg "define_chroot_env() CHROOT_TO not defined!"
    [ ! -d "$CHROOT_TO" ] && error_msg "define_chroot_env() - path does not exist: $CHROOT_TO"

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

use_root_shell_as_default_cmd() {
    #
    #  Since no command was specified, try to extract the root
    #  shell from within the env. This to ensue we dont try
    #  to use a shell that is either not available, nor
    #  not found in the expeted location
    #
    [ "$_fnc_calls" -gt 0 ] && msg_2 "use_root_shell_as_default_cmd()"

    f_etc_pwd="${CHROOT_TO}/etc/passwd"
    [ ! -f "$f_etc_pwd" ] && error_msg "Trying to find chrooted root shell in its /etc/passwd failed"
    cmd_w_params="$(awk -F: '/^root:/ {print $NF" -l"}' "$f_etc_pwd")"
    unset f_etc_pwd

    [ "$_fnc_calls" = 2 ] && msg_3 "use_root_shell_as_default_cmd() - done"
}

env_prepare() {
    [ "$_fnc_calls" -gt 0 ] && msg_2 "env_prepare()"

    ensure_dev_paths_are_defined "skip_pts"

    _err="$prog_name is running! - this should have already been caught!"
    [ -f "$pidfile_do_chroot" ] && error_msg "$_err"
    unset _err

    # msg_3 "creating pidfile_do_chroot: $pidfile_do_chroot"
    echo "$$" >"$pidfile_do_chroot"

    [ ! -d "$CHROOT_TO" ] && error_msg "chroot location [$CHROOT_TO] is not a directory!"

#    if mount | grep -q "$CHROOT_TO"; then
#        error_msg "This [$CHROOT_TO] is already chrooted!"
#    fi

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
#	mount -o bind /dev/pts "$d_dev_pts"
    fi

    # msg_3 "copying current /etc/resolv.conf"
    cp /etc/resolv.conf "$CHROOT_TO/etc"

    [ "$_fnc_calls" = 2 ] && msg_3 "env_prepare() - done"
}

#  shellcheck disable=SC2120
env_restore() {
    #
    #  This would normally be called as a mount session is terminating
    #  so therefore the pidfile_do_chroot should not be checked.
    #  Assume that if we get here we can do the cleanup.
    #
    if [ "$_fnc_calls" -gt 0 ]; then
        if [ -n "$env_restore_started" ]; then
            msg_1 "env_restore() has already been called, skipping"
            return
        fi
        msg_2 "env_restore()"
    else
        [ -n "$env_restore_started" ] && return
    fi
    env_restore_started=1
    ensure_dev_paths_are_defined skip_pts

    msg_2 "Releasing system resources"
    kill_remaining_procs
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

    #
    #  Complain about pottenially bad pidfile_do_chroot after completing the procedure
    #
    [ -z "$pidfile_do_chroot" ] && error_msg "pidfile_do_chroot is undefined!"

    [ -n "$pidfile_do_chroot" ] && {
        # msg_3 "removing pidfile_do_chroot: $pidfile_do_chroot"
        rm -f "$pidfile_do_chroot"
    }

    [ "$_fnc_calls" = 2 ] && msg_3 "env_restore() - done"
}

show_help() {
    # msg_2 "show_help()"

    echo "
Usage: $prog_name [-h] [-a] [-c] [-C] [-p dir] [command]

Available options:

-h  --help      Print this help and exit
-a  --available Reports if this can be run now
-c  --cleanup   Cleanup env if something crashed whilst sudoed
-p, --path      What dir to chroot into, defaults to: $d_build_root
command         Defaults to the shell used by root within the env

chroot with env setup so this works on both Linux & iSH

Normally this will clear up the env even if the chroot crashes.
If it does  fail to clean up, and you attempt to run with -c
used -p to chroot to a custom path, you must take care to give
-p BEFORE -c in order for this to know what reminant mount points to
clean up!

"
    # msg_3 "show_help() - done"
}

chroot_statuses() {
    #
    #  This is mostly a debug helper, so only informative
    #  does not contribute to the actual process
    #
    [ "$_fnc_calls" -gt 0 ] && msg_2 "chroot_statuses($1)"

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
    [ "$_fnc_calls" = 2 ] && msg_3 "chroot_statuses($1) - done"
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

CHROOT_TO="$d_build_root"

if this_is_ish && hostfs_is_debian; then
    echo "************"
    echo "ish running Debian - this does not seem able to do chroot. You have been warned..."
    echo "************"
fi

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
cd "$aok_content" || {
    error_msg "Failed to cd into: $aok_content"
}

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
    cleanup_sleep=2
    can_chroot_run_now
    echo
    echo "Will cleanup the mount point: $CHROOT_TO"
    echo
    echo "Please be aware that if you attempt to clean up after a chroot"
    echo "to a non-standard path (ie you used -p), you must use this notation"
    echo "in order to attempt to clean up the right things."
    echo
    echo "$prog_name -p /custom/path -c"
    echo
    echo "This will continue in $cleanup_sleep secnods, hit Ctrl-C if you want to abort"
    sleep "$cleanup_sleep"

    define_chroot_env
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

define_chroot_env
can_chroot_run_now

#
#  In case something fails, always try to unmount
#
trap 'cleanup INT' INT
trap 'cleanup TERM' TERM

env_prepare

[ -z "$d_build_root" ] && error_msg "d_build_root empty!" 1

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
        if ! [ -f "${d_build_root}${_cmd}" ]; then
            msg_1 "Might not work, file not found: ${d_build_root}${_cmd}"
        elif ! [ -x "${d_build_root}${_cmd}" ]; then
            msg_1 "Might not work, file not executable: ${d_build_root}${_cmd}"
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
    msg_2 "d_build_root [$d_build_root]"
    msg_3 "Detected: [$(destfs_detect)]"
    echo
    echo ">>> -----  displaying host fs status"
    find /etc/opt
    echo ">>> -----"
    echo
    echo ">>> -----  displaying dest fs status"
    find "$d_build_root"/etc/opt
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
#
#  TODO: try to get rid of emptying vars
#  shellcheck disable=SC2086
TMPDIR="" SHELL="" LANG="" chroot "$CHROOT_TO" $cmd_w_params
chroot_exit_code="$?"

[ -n "$DEBUG_BUILD" ] && msg_1 "----------  back from chroot  ----------"

env_restore
destfs_clear_chrooted

# If there was an error in the chroot process, propagate it
exit "$chroot_exit_code"
