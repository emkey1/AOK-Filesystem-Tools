#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#  shellcheck disable=SC2034,SC2154
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Environment variables used when building the AOK-FS
#

#
#  Display an error message, second optional param is exit code,
#  defaulting to 1. If exit code is no_exit this will not exit, just display
#  the error message, then continue.
#

error_msg() {
    _em_msg="$1"
    _em_exit_code="${2:-1}"
    if [ -z "$_em_msg" ]; then
        echo
        echo "error_msg() no param"
        exit 9
    elif [ "$_em_exit_code" = "0" ]; then
        echo
        echo "error_msg() second parameter was 0"
        echo "            if continuation is desired use no_exit"
        exit 9
    fi

    _em_msg="ERROR: $_em_msg"
    echo
    echo "$_em_msg"
    echo

    if [ "$_em_exit_code" = "no_exit" ]; then
        echo "no_exit given, will continue"
        echo
    else
        exit "$_em_exit_code"
    fi
    unset _em_msg
    unset _em_exit_code
}

debug_sleep() {
    # echo "=V= debug_sleep($1,$2)"
    _ds_msg="$1"
    [ -z "$_ds_msg" ] && error_msg "debug_sleep() - no msg param"

    _ds_t_slp="$2"
    [ -z "$_ds_t_slp" ] && error_msg "debug_sleep($msg) - no time param"

    msg_1 "$_ds_msg - ${_ds_t_slp}s sleep"
    sleep "$_ds_t_slp"

    unset _ds_msg
    unset _ds_t_slp
    # echo "^^^ debug_sleep() - done"
}

#
#  The msg_ functions are ordered, lower number infers more important updates
#  so they should stand out more
#
do_msg() {
    _msg="$1"
    [ -z "$_msg" ] && error_msg "do_msg() no param"
    echo "$_msg"
    unset _msg
}

msg_1() {
    [ -z "$1" ] && error_msg "msg_1() no param"
    echo
    do_msg "===  $1  ==="
    echo
}

msg_2() {
    [ -n "$1" ] || error_msg "msg_2() no param"
    do_msg "---  $1"
}

msg_3() {
    [ -n "$1" ] || error_msg "msg_3() no param"
    do_msg " --  $1"
}

msg_4() {
    [ -n "$1" ] || error_msg "msg_4() no param"
    do_msg "  -  $1"
}

msg_script_title() {
    [ -z "$1" ] && error_msg "msg_script_title() no param"
    echo
    echo "***"
    echo "***  $1"
    if [ -f "$f_aok_fs_release" ]; then
        echo "***"
        echo "***    creating AOK-FS: $(cat "$f_aok_fs_release")"
    fi
    echo "***"
    echo
}

display_time_elapsed() {
    # echo "=V= tools/utils display_time_elapsed($1, $2) $(date)"
    dte_t_in="$1"
    dte_label="$2"
    #  Save prebuild time, so it can be added when finalizing deploy
    f_dte_pb=/tmp/prebuild-time

    if [ -f "$f_dte_pb" ] && deploy_state_is_it "$deploy_state_finalizing"; then
        dte_prebuild_time="$(cat "$f_dte_pb")" || error_msg "Failed to read $f_dte_pb"
        # rm -f "$f_dte_pb"
        dte_t_in="$((dte_prebuild_time + dte_t_in))"
        echo "$dte_t_in" >"$f_dte_pb"
        unset dte_prebuild_time
    fi

    dte_mins="$((dte_t_in / 60))"
    dte_seconds="$((dte_t_in - dte_mins * 60))"

    [ -z "$d_build_root" ] && deploy_state_is_it "$deploy_state_pre_build" && {
        echo "$dte_t_in" >>"$f_dte_pb"
    }

    #  Add zero prefix when < 10
    [ "$dte_mins" -gt 0 ] && [ "$dte_mins" -lt 10 ] && dte_mins="0$dte_mins"
    [ "$dte_seconds" -lt 10 ] && dte_seconds="0$dte_seconds"

    echo
    echo "display_time_elapsed - Time elapsed: $dte_mins:$dte_seconds - $dte_label"
    echo

    unset dte_t_in
    unset dte_label
    unset f_dte_pb
    unset dte_mins
    unset dte_seconds
    # echo "^^^ tools/utils display_time_elapsed() - done"
}

untar_file() {
    _tarball="$1"
    _tar_params="${2:-z}"
    _no_exit="$3" # set to NO_EXIT_ON_ERROR if untar failures should not cause abort

    [ -z "$_tarball" ] && error_msg "untar_file() - no param"

    if [ "${#_tarball}" -lt 15 ]; then
        msg_3 "Unpacking $_tarball into: $(pwd)"
    else
        msg_3 "Unpacking: $_tarball"
        msg_3 "     into: $(pwd)"
    fi

    if [ -n "$cmd_pigz" ]; then
        # pigz -dc your_archive.tgz | tar -xf -
        msg_4 "Using $cmd_pigz"
        # pigz doesnt need z or j params
        _tar_params="$(echo "$_tar_params" | sed 's/z//' | sed 's/j//')"
        $cmd_pigz -dc "$_tarball" | tar -xf"$_tar_params" - || {
            [ "$_no_exit" != "NO_EXIT_ON_ERROR" ] && error_msg "Failed to untar $_tarball"
        }
    else
        msg_4 "No pigz"
        tar "xf${_tar_params}" "$_tarball" || {
            [ "$_no_exit" != "NO_EXIT_ON_ERROR" ] && error_msg "Failed to untar $_tarball"
        }
    fi

    unset _tarball
    unset _tar_params
    unset _no_exit
    msg_4 "Unpacking - done"
}

create_fs() {
    #
    #  Extract a $1 tarball at $2 location - verbose flag $3
    #
    # echo "=V= create_fs()"
    _cf_tarball="$1"
    [ -z "$_cf_tarball" ] && error_msg "cache_fs_image() no taball supplied"
    _cf_fs_location="${2:-$d_build_root}"
    msg_3 "will be deployed in: $_cf_fs_location"
    _cf_verbose="${3:-false}"
    if $_cf_verbose; then # verbose mode
        _cf_verbose="v"
    else
        _cf_verbose=""
    fi
    [ -z "$_cf_fs_location" ] && error_msg "no _cf_fs_location detected"
    mkdir -p "$_cf_fs_location"
    cd "$_cf_fs_location" || {
        error_msg "Failed to cd into: $_cf_fs_location"
    }

    msg_3 "Extracting tarball, unpack time will be displayed"
    case "$src_tarball" in
    *alpine*) _cf_time_estimate="A minirootfs should not take that long" ;;
    *)
        _cf_time_estimate="will take a while (iPad 5th:8, iPad 7th:4 minutes)"
        ;;
    esac
    msg_3 "  $_cf_time_estimate"
    unset _cf_time_estimate

    if test "${_cf_tarball#*tgz}" != "$_cf_tarball" || test "${_cf_tarball#*tar.gz}" != "$_cf_tarball"; then
        _cf_filter="z"
    else
        msg_3 "detected bzip2 format"
        _cf_filter="j"
    fi

    t_img_extract_start="$(date +%s)"
    untar_file "$_cf_tarball" "${_cf_verbose}${_cf_filter}"

    t_img_extract_duration="$(($(date +%s) - t_img_extract_start))"
    display_time_elapsed "$t_img_extract_duration" "Extract image"
    unset t_img_extract_start
    unset t_img_extract_duration

    deploy_state_set "$deploy_state_initializing"

    unset _cf_tarball
    unset _cf_fs_location
    unset _cf_verbose
    unset _cf_filter
    # echo "^^^ create_fs() - done"
}

min_release() {
    #
    #  Param is major release, like 3.16 or 3.17
    #  returns true if the current release matches or is higher
    #
    rel_min="$1"
    [ -z "$rel_min" ] && error_msg "min_release() no param given!"

    # For edge always return true
    [ "$ALPINE_VERSION" = "edge" ] && return 0

    rel_this="$(echo "$ALPINE_VERSION" | cut -d"." -f 1,2)"
    _result=$(awk -v x="$rel_min" -v y="$rel_this" 'BEGIN{if (x > y) print 1; else print 0}')

    if [ "$_result" -eq 1 ]; then
        return 1 # false
    elif [ "$_result" -eq 0 ]; then
        return 0 # true
    else
        error_msg "min_release() Failed to compare releases"
    fi
}

#
#  Display warning message indicating that errors displayed during
#  openrc actions can be ignored, and are not to be read as failures in
#  the deploy procedure.
#
openrc_might_trigger_errors() {
    echo
    echo "You might see a few errors printed as services are toggled."
    echo "The iSH family doesn't fully support openrc yet, but the important parts work!"
    echo
}

manual_runbg() {
    #
    #  Only start if not running
    #
    #  shellcheck disable=SC2009
    if ! this_fs_is_chrooted && ! ps ax | grep -v grep | grep -qw cat; then
        cat /dev/location >/dev/null &
        msg_1 "iSH now able to run in the background"
    fi
}

initiate_deploy() {
    # echo "=V= initiate_deploy($1, $2)"
    #
    #  If either is not found, we dont know what to install and how
    #
    # [ ! -f "$f_build_type" ] && error_msg "$f_build_type missing, unable to deploy"

    _ss_distro_name="$1"
    [ -z "$_ss_distro_name" ] && error_msg "initiate_deploy() no distro_name provided"
    _ss_vers_info="$2"
    [ -z "$_ss_vers_info" ] && error_msg "initiate_deploy() no vers_info provided"

    deploy_starting

    # buildtype_set "$_ss_distro_name"

    if [ -n "$PREBUILD_ADDITIONAL_TASKS" ]; then
        msg_3 "At the end of the pre-build, additioal tasks will be run:"
        echo "--------------------"
        echo "$PREBUILD_ADDITIONAL_TASKS"
        echo "--------------------"
        echo
    fi
    if [ -n "$FIRST_BOOT_ADDITIONAL_TASKS" ]; then
        msg_3 "At the end of the install, additioal tasks will be run:"
        echo "--------------------"
        echo "$FIRST_BOOT_ADDITIONAL_TASKS"
        echo "--------------------"
        echo
    fi

    msg_1 "Setting up ${_ss_distro_name}: $_ss_vers_info"

    manual_runbg

    if destfs_is_alpine; then
        copy_local_bins Alpine
    else
        copy_local_bins FamDeb
    fi

    unset _ss_distro_name
    unset _ss_vers_info
    # echo "^^^ initiate_deploy() - done"
}

#  shellcheck disable=SC2120
set_new_etc_profile() {
    # echo "=V= set_new_etc_profile($1)"
    sp_new_profile="$1"
    if [ -z "$sp_new_profile" ]; then
        error_msg "set_new_etc_profile() - no param"
    fi

    #
    #  Avoid file replacement whilst running doesnt overwrite the
    #  previous script without first removing it, leaving a garbled file
    #
    rm "$d_build_root"/etc/profile

    if [ "$(basename "$sp_new_profile")" = "profile" ]; then
        cp -a "$sp_new_profile" "$d_build_root"/etc/profile
    else
        (
            echo "#"
            echo "#  Script that is part of deploy,  wrap it inside other script"
            echo "#  so that any error exits dont exit ish, just aborts deploy"
            echo "#  special case exit 123 exits the profile, useful for prebuild"
            echo "#  to exit out of the chroot"
            echo "#"
            echo "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            echo "$sp_new_profile"
            echo 'ex_code="$?"'
            #  shellcheck disable=SC2016
            echo '[ "$ex_code" = "123" ] && exit  # 123=prebuild done, exit without error' # use single quotes so $? isnt expanded here
            #  shellcheck disable=SC2016
            echo 'if [ "$ex_code" -ne 0 ]; then'

            #
            #  Use printf without linebreak to use continuation to
            #  do first part of line expanding variables, and second part
            #  not expanding them
            #
            printf "    echo \"ERROR: %s exited with code: " "$sp_new_profile"
            #  shellcheck disable=SC2016
            echo '$ex_code"'
            echo "fi"
            echo ""
            echo "#"
            echo "#  Since the deploy script was run in a subshell, its path"
            echo "#  cant be shared when exiting deploy and dropping into an"
            echo "#  interactive env, so here comes a generic path"
            echo "#"
        ) >"$d_build_root"/etc/profile
    fi

    #
    #  Normaly profile is sourced, but in order to be able to directly
    #  run it if manually triggering a deploy, make it executable
    #
    chmod 744 "$d_build_root"/etc/profile
    unset sp_new_profile
    # echo "^^^ set_new_etc_profile() - done"
}

rsync_chown() {
    #
    #  params: src dest [silent]
    #  Copy then changing ovnership to root:
    #  If silent is given, no progress will be displayed
    #
    # echo "=V= rsync_chown($1, $2, $3)"
    src="$1"
    d_dest="$2"
    [ -z "$src" ] && error_msg "rsync_chown() no source param"
    [ -z "$d_dest" ] && error_msg "rsync_chown() no dest param"
    [ -n "$3" ] && _silent_mode=1

    #
    #  rsync is used early on in deploy, so make sure it is installed
    #  before attempt to use it
    #
    if [ -z "$(command -v rsync)" ]; then
        msg_3 "Installing rsync"
        if destfs_is_alpine; then
            apk add rsync >/dev/null 2>&1 || error_msg "Failed to install rsync"
        else
            # Debian imgs normally have it already installed, this is just in case
            msg_3 "Ensuring rsync is available"
            apt install rsync >/dev/null 2>&1 || {
                error_msg "Failed to install rsync"
            }
        fi
    fi

    _r_params="-ah --exclude="'*~'" --chown=root:root $src $d_dest"
    if [ -n "$_silent_mode" ]; then
        #  shellcheck disable=SC2086
        rsync $_r_params >/dev/null || {
            error_msg "rsync_chown($src, $d_dest, silent) failed"
        }
    else
        #
        #  In order to only list actually changed files,
        #  skip lines starting with whitespace - xfer stats
        #  and the specific lines:
        #   sending incremental file list
        #   ./
        #
        # rsync -P $_r_params | grep -v -e '\^./$' -e '^sending incremental' -e '^\[[:space:]]' || {
        rsync_output=/tmp/aok-rsync-chown-output
        #  shellcheck disable=SC2086
        rsync -P $_r_params >"$rsync_output" || {
            error_msg "rsync_chown($src, $d_dest) failed"
        }
        grep -v -e '^./$' -e '^sending incremental' -e '^[[:space:]]' "$rsync_output"
        case "$?" in
        0 | 1) ;; # 0=something found 1=nothing found
        *)        # actual error
            error_msg "filtering output of rsync_chown() failed"
            ;;
        esac
    fi
    unset src
    unset d_dest
    unset _silent_mode
    # echo "^^^ rsync_chown() - done"
}

copy_local_bins() {
    # echo "=V= copy_local_bins($1)"
    _clb_base_dir="$1"
    if [ -z "$_clb_base_dir" ]; then
        error_msg "call to copy_local_bins() without param!"
    fi

    # msg_1 "Copying /usr/local stuff from $_clb_base_dir"
    _clb_src_dir="/opt/AOK/${_clb_base_dir}/usr_local_bin"
    if [ -z "$(find "$_clb_src_dir" -type d -empty)" ]; then
        msg_3 "Add $_clb_base_dir AOK-FS stuff to /usr/local/bin"
        mkdir -p /usr/local/bin
        rsync_chown "$_clb_src_dir/*" /usr/local/bin silent
    fi

    _clb_src_dir="/opt/AOK/${_clb_base_dir}/usr_local_sbin"
    if [ -d "$_clb_src_dir" ]; then
        msg_3 "Add $_clb_base_dir AOK-FS stuff to /usr/local/sbin"
        mkdir -p /usr/local/sbin
        rsync_chown "$_clb_src_dir/*" /usr/local/sbin silent
    fi
    unset _clb_base_dir
    unset _clb_src_dir
    # echo "^^^ copy_local_bins() - done"
}

display_installed_versions_if_prebuilt() {
    if deploy_state_is_it "$deploy_state_pre_build"; then
        echo
        /usr/local/bin/aok-versions
    fi
}

ensure_ish_or_chrooted() {
    #
    #  Simple test to make sure this is not run on a non iSH host
    #
    this_is_ish && return
    this_fs_is_chrooted && return
    error_msg "Can only run on iSH or when chrooted"
}

strip_str() {
    [ -z "$1" ] && error_msg "strip_str() - no param"
    echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

fix_stdio_device() {
    dev_src="$1"
    dev_name="/dev/$2"

    [ -c "$dev_name" ] || {
        msg_4 "Replacing $dev_name"
        rm -f "$dev_name"
        ln -sf "$dev_src" "$dev_name"
    }
    return 0
}

fix_stdio() {
    msg_3 "Ensuring stdio devices are setup"
    fix_stdio_device /proc/self/fd/0 stdin
    fix_stdio_device /proc/self/fd/1 stdout
    fix_stdio_device /proc/self/fd/2 stderr
}

#---------------------------------------------------------------
#
#   boolean checks
#
#---------------------------------------------------------------

this_is_ish() {
    test -d /proc/ish
}

this_is_aok_kernel() {
    grep -qi aok /proc/ish/version 2>/dev/null
}

#---------------------------------------------------------------
#
#   Launch Command
#
#---------------------------------------------------------------

verify_launch_cmd() {
    this_is_ish || return

    msg_2 "Verifying expected 'Launch cmd'"

    launch_cmd_current="$(get_launch_cmd)"
    if [ "$launch_cmd_current" != "$launch_cmd_AOK" ]; then
        msg_1 "'Launch cmd' is not the default for AOK"
        echo "Current 'Launch cmd': '$launch_cmd_current'"
        echo
        echo "To set the default, run this, it will display the updated content:"
        echo
        echo "aok --launch-cmd aok"
        # echo "sudo echo '$launch_cmd_AOK' > $f_launch_cmd"
        echo
    fi
}

restore_launch_cmd() {
    #
    #  In case something goes wrong use this to (hopefully) ensure
    #  it's restored
    #

    #  Does not use set_launch_cmd in order to prevent risk for infinite loops
    echo "$launch_cmd_default" >"$f_launch_cmd"

    # is safe to call even here in a "exception handler"
    _slc_current="$(get_launch_cmd)"
    if [ "$_slc_current" != "$launch_cmd_default" ]; then
        echo
        echo "ERROR: Failed to restore launch cmd!"
        echo
        echo "Current launch cmd: $_slc_current"
        echo "Intended default:   $launch_cmd_default"
        echo
        echo "Make sure to set it manually, otherwise iSH will probably"
        echo "fail to start!"
        exit 1
    fi
    unset _slc_current
}

get_launch_cmd() {
    #
    #  It is reported as a multiline, here it is wrapped into a one-line
    #  notation, to make it easier to compare vs the launch_md_XXX
    #  templates
    #
    if this_fs_is_chrooted; then
        echo "Launch cmd not available when chrooted"
        exit
    fi
    tr -d '\n' <"$f_launch_cmd" | sed 's/  \+/ /g' | sed 's/"]/" ]/'
}

set_launch_cmd() {
    _slc_cmd="$1"
    [ -z "$_slc_cmd" ] && error_msg "set_launch_cmd() - no param"
    if this_fs_is_chrooted; then
        echo "Launch cmd not available when chrooted"
        exit
    fi
    echo "$_slc_cmd" >"$f_launch_cmd"
    _slc_current="$(get_launch_cmd)"
    [ "$_slc_current" = "$_slc_cmd" ] || {
        echo
        echo "ERROR: Failed to set Launch cmd"
        echo
        echo "Sample syntax: '$launch_cmd_default'"
        echo "intended: '$_slc_cmd'"
        echo "current:  '$_slc_current'"
        restore_launch_cmd "Failed to set a launch command"
        exit 1
    }
    unset _slc_cmd
    unset _slc_current
}

# each param MUST be wrapped in ""...

f_launch_cmd="/proc/ish/defaults/launch_command"
launch_cmd_AOK='[ "/usr/local/sbin/aok_launcher" ]'
launch_cmd_default='[ "/bin/login", "-f", "root" ]'

#---------------------------------------------------------------
#
#   chroot handling
#
#---------------------------------------------------------------

this_fs_is_chrooted() {
    #  Check this _ACTUAL_ fs
    [ -f "$f_host_fs_is_chrooted" ]
}

dest_fs_is_chrooted() {
    [ -f "$f_dest_fs_is_chrooted" ]
}

destfs_set_is_chrooted() {
    # echo "=V= destfs_set_is_chrooted(()"
    if [ "$f_dest_fs_is_chrooted" = "$f_host_fs_is_chrooted" ]; then
        msg_2 "f_dest_fs_is_chrooted same as f_host_fs_is_chrooted"
        msg_3 "$f_dest_fs_is_chrooted"
        error_msg "flagging dest FS as chrooted NOT possible!"
    fi
    mkdir -p "$(dirname "$f_dest_fs_is_chrooted")"
    touch "$f_dest_fs_is_chrooted"
    # echo "^^^ destfs_set_is_chrooted(() - done"
}

destfs_clear_chrooted() {
    # echo "=V= destfs_clear_chrooted(()"

    if [ "$f_dest_fs_is_chrooted" = "$f_host_fs_is_chrooted" ]; then
        msg_2 "f_dest_fs_is_chrooted same as f_host_fs_is_chrooted"
        msg_3 "$f_dest_fs_is_chrooted"
        error_msg "clearing dest FS as chrooted NOT possible!"
    fi

    if [ -f "$f_dest_fs_is_chrooted" ]; then
        rm "$f_dest_fs_is_chrooted"
    else
        error_msg "destfs_clear_chrooted() - could not find chroot indicator"
    fi
    # echo "^^^ destfs_clear_chrooted(() - done"
}

#---------------------------------------------------------------
#
#   Host FS
#
#  What this FS is
#
#---------------------------------------------------------------

hostfs_is_alpine() {
    test -f /etc/alpine-release
}

hostfs_is_debian() {
    test -f /etc/debian_version && ! hostfs_is_devuan
}

hostfs_is_devuan() {
    test -f /etc/devuan_version
}

hostfs_detect() {
    #
    #
    #  Since a select env also looks like Alpine, this must fist
    #  test if it matches the test criteria
    #
    #error_msg 'abort in hostfs_detect()'
    if hostfs_is_alpine; then
        echo "$distro_alpine"
    elif hostfs_is_debian; then
        echo "$distro_debian"
    elif hostfs_is_devuan; then
        echo "$distro_devuan"
    else
        #  Failed to detect
        echo
    fi
}

#---------------------------------------------------------------
#
#   Destination FS
#
#  destfs from the perspective of a build host
#
#---------------------------------------------------------------

destfs_is_alpine() {
    ! destfs_is_select && test -f "$f_alpine_release"
}

destfs_is_debian() {
    test -f "$d_build_root"/etc/debian_version && ! destfs_is_devuan
}

destfs_is_devuan() {
    test -f "$d_build_root"/etc/devuan_version
}

destfs_is_select() {
    [ -f "$f_destfs_select_hint" ]
}

destfs_detect() {
    #
    #  Since a select env also looks like Alpine, this must fist
    #  test if it matches the test criteria
    #
    if destfs_is_select; then
        echo "$destfs_select"
    elif destfs_is_alpine; then
        echo "$distro_alpine"
    elif destfs_is_debian; then
        echo "$distro_debian"
    elif destfs_is_devuan; then
        echo "$distro_devuan"
    else
        #  Failed to detect
        echo
    fi
}

#---------------------------------------------------------------
#
#   lsb-release
#
#   get_lsb_release will install lsb-release tools if not present
#   and set the two variables:
#      lsb_DistributorID
#      lsb_Release
#
#---------------------------------------------------------------

#  shellcheck disable=SC2120
get_lsb_release() {
    #
    #  If param 1 is chroot, then this will display lsb info for the
    #  dest fs, such as when compressing an FS
    #
    _do_chroot="$1"

    if destfs_is_alpine; then
        ! min_release "3.17" && {
            # lsb_release not available on older Alpines
            lsb_DistributorID="Alpine"
            lsb_Release="$ALPINE_VERSION"
            return
        }
    fi

    f_lsb_bin=/usr/bin/lsb_release
    _f=/tmp/aok-lsb_info.tmp

    if [ "$_do_chroot" = "chroot" ]; then
        #  Install lsb_release if not available
        if ! /opt/AOK/tools/do_chroot.sh "which lsb_release" >/dev/null 2>&1; then
            msg_4 "lsb-release-minimal will be installed!"
            if destfs_is_alpine; then
                /opt/AOK/tools/do_chroot.sh "apk add lsb-release-minimal" >/dev/null 2>&1 ||
                    error_msg "Failed to install lsb-release-minimal"
            elif destfs_is_devuan || destfs_is_debian; then
                /opt/AOK/tools/do_chroot.sh "apt install -y lsb-release" >/dev/null 2>&1 ||
                    error_msg "Failed to install lsb-release"
            else
                error_msg "Don't know how to install lsb-release on this platform"
            fi
        fi
        /opt/AOK/tools/do_chroot.sh "$f_lsb_bin -a" >"$_f" 2>/dev/null
    else
        if ! command -v lsb_release >/dev/null 2>&1; then
            msg_4 "lsb-release-minimal will be installed!"
            if destfs_is_alpine; then
                apk add lsb-release-minimal || error_msg "Failed to install lsb-release-minimal"
            elif destfs_is_devuan || destfs_is_debian; then
                apt install -y lsb-release || error_msg "Failed to install lsb-release"
            else
                error_msg "Don't know how to install lsb-release on this platform"
            fi
        fi
        lsb_release -a 2>/dev/null >"$_f"
    fi

    while IFS=':' read -r key value; do
        key=$(printf '%s' "$key" | tr -d '[:space:]')
        case "$key" in
        DistributorID) lsb_DistributorID="$(strip_str "$value")" ;;
        Release) lsb_Release="$(strip_str "$value")" ;;
        *) ;;
        esac
    done <"$_f"
    [ -z "$lsb_DistributorID" ] && error_msg "no DistributorID lsb record found"
    [ -z "$lsb_Release" ] && error_msg "no Release lsb record found"

    rm -f "$_f" || error_msg "Failed to remove tmp file: $_f"

    unset _do_chroot
    unset _f
    unset key
    unset value
}

#---------------------------------------------------------------
#
#   Deployment state
#
#  Kepps track on in what stage the deployment is
#
#   up to deploy_state_creating allways happens on build host
#
#---------------------------------------------------------------

deploy_state_set() {
    # msg_1 "===============   deploy_state_set($1)   ============="
    _state="$1"
    [ -z "$_state" ] && error_msg "buildstate_set() - no param!"

    deploy_state_check_param deploy_state_set "$_state"

    mkdir -p "$(dirname "$f_dest_fs_deploy_state")"
    echo "$_state" >"$f_dest_fs_deploy_state"

    unset _state
}

deploy_state_is_it() {
    #
    #  Checks if the current deployment state matches the requested
    #
    _state="$1"
    [ -z "$_state" ] && error_msg "deploy_state_is_it() - no param!"

    deploy_state_check_param deploy_state_is_it "$_state"

    [ "$_state" = "$(deploy_state_get)" ]
    # _state is not unset, but shouldnt be an issue
}

deploy_state_get() {
    _state="$(cat "$f_dest_fs_deploy_state" 2>/dev/null)"
    if [ -n "$_state" ]; then
        echo "$_state"
    fi
    unset _state
}

deploy_state_check_param() {
    _func="$1"
    [ -z "$_func" ] && error_msg "deploy_state_check_param() - no function param!"
    _state="$2"
    [ -z "$_state" ] && error_msg "deploy_state_check_param() - no deploy state param!"

    case "$_state" in
    "$deploy_state_na" | "$deploy_state_initializing" | \
        "$deploy_state_pre_build" | "$deploy_state_dest_build" | \
        "$deploy_state_finalizing") ;;
    *) error_msg "${_func}($_state) - invalid param!" ;;
    esac

    unset _func
    unset bspc_bs
}

deploy_starting() {
    if [ "$build_env" = "$be_other" ]; then
        echo
        echo "##  WARNING! this setup only works reliably on iOS/iPadOS and Linux(x86)"
        echo "##           You have been warned"
        echo
    fi

    if deploy_state_is_it "$deploy_state_initializing"; then
        deploy_state_set "$deploy_state_dest_build"
    elif ! deploy_state_is_it "$deploy_state_pre_build"; then
        error_msg "Dest FS in an unknown state [$(deploy_state_get)], can't continue"
    fi
}

replace_home_user() {
    [ -f "$f_home_user_replaced" ] && {
        msg_2 "HOME_DIR_USER already replaced"
        return
    }

    [ -n "$HOME_DIR_USER" ] && {
        if [ -f "$HOME_DIR_USER" ]; then
            [ -z "$USER_NAME" ] && error_msg "USER_HOME_DIR defined, but not USER_NAME"
            msg_2 "Replacing /home/$USER_NAME"
            cd "/home" || error_msg "Failed cd /home"
            rm -rf "$USER_NAME"
            untar_file "$HOME_DIR_USER" z # NO_EXIT_ON_ERROR
            touch "$f_home_user_replaced"
        else
            error_msg "HOME_DIR_USER file not found: $HOME_DIR_USER" no_exit
        fi
    }
}

replace_home_root() {
    [ -f "$f_home_root_replaced" ] && {
        msg_2 "HOME_DIR_ROOT already replaced"
        return
    }
    [ -n "$HOME_DIR_ROOT" ] && {
        if [ -f "$HOME_DIR_ROOT" ]; then
            msg_2 "Replacing /root"
            mv /root /root.ORIG
            cd / || error_msg "Failed to cd into: /"
            untar_file "$HOME_DIR_ROOT" z # NO_EXIT_ON_ERROR
            touch "$f_home_root_replaced"
        else
            error_msg "HOME_DIR_ROOT file not found: $HOME_DIR_ROOT" no_exit
        fi
    }
}

replace_home_dirs() {
    replace_home_user
    replace_home_root
}

#===============================================================
#
#   Main
#
#===============================================================

#
#  Import default settings
#
_f=/opt/AOK/AOK_VARS
#  shellcheck source=/opt/AOK/AOK_VARS
. "$_f" || error_msg "Not found: $_f"

#
#  Read .AOK_VARS if pressent, allowing it to overide AOK_VARS
#
# if [ "$(echo "$0" | sed 's/\// /g' | awk '{print $NF}')" = "build_fs" ]; then
_f=/opt/AOK/.AOK_VARS
if [ -f "$_f" ]; then
    # msg_2 "Found .AOK_VARS"
    #  shellcheck disable=SC1090
    . "$_f"
fi

TMPDIR="${TMPDIR:-/tmp}"

#
#  Used for keeping track of deploy / chroot status
#
d_aok_etc=/etc/opt/AOK

#
#  Figure out if this script is run as a build host
#  or inside the dest File System
#
#  To make things work regardless, a build host adds
#  a prefix to all absolute paths - d_build_root
#  pointing to where the dest fs is located in the host fs
#
f_host_fs_is_chrooted="$d_aok_etc"/this_fs_is_chrooted
f_host_deploy_state="$d_aok_etc"/deploy_state

if ! this_fs_is_chrooted && [ ! -f "$f_host_deploy_state" ]; then
    d_build_root="$TMPDIR"/aok_fs
else
    d_build_root=""
fi

f_dest_fs_is_chrooted="${d_build_root}${f_host_fs_is_chrooted}"
f_dest_fs_deploy_state="${d_build_root}${f_host_deploy_state}"

#
#  Detecting build environments
#  0 = other, not able to chroot to complete image
#  1 = iSH
#  2 = Linux (x86)
#
#  >0   != "$be_other"  - no chroot

be_ish="Build env iSH"
be_linux="Build env x86 Linux"
be_other="Build env other"
if this_is_ish; then
    build_env="$be_ish" # 1
elif uname -a | grep -qi linux && uname -a | grep -q -e x86 -e i686; then
    build_env="$be_linux" # 2
else
    build_env="$be_other" # chroot not possible 0
fi

#
#  Locations for "other" stuff
#

#  Location for src images
d_src_img_cache="$TMPDIR"/aok_cache

#
#  If this is built on an iSH node, and iCloud is mounted, the image is
#  copied to this location
#
d_icloud_archive=/iCloud/AOK_Archive

#
#  Names of the rootfs tarballs used for initial population of FS
#
debian_src_tb="$(echo "$DEBIAN_SRC_IMAGE" | cut -d'?' -f1 | grep -oE '[^/]+$')"
devuan_src_tb="$(echo "$DEVUAN_SRC_IMAGE" | cut -d'?' -f1 | grep -oE '[^/]+$')"

#
#  Extract the release/branch/major version, from the requested Alpine,
#  gives something like 3.14
#

alpine_src_tb="alpine-minirootfs-${ALPINE_VERSION}-x86.tar.gz"
if echo "$ALPINE_VERSION" | grep -Eq '^[0-9]{8}$'; then
    alpine_release="edge"
    alpine_src_image="https://dl-cdn.alpinelinux.org/alpine/edge/releases/x86/$alpine_src_tb"
else
    alpine_release="$(echo "$ALPINE_VERSION" | cut -d"." -f 1,2)"
    alpine_src_image="https://dl-cdn.alpinelinux.org/alpine/v${alpine_release}/releases/x86/$alpine_src_tb"
fi

#  Where to find native FS version
f_alpine_release="$d_build_root"/etc/alpine-release
f_debian_version="$d_build_root"/etc/debian_version

#  Placeholder, to store what version of AOK that was used to build FS
f_aok_fs_release="$d_build_root"/etc/aok-fs-release

#
#  Either run this script chrooted if the host OS supports it, or run it
#  inside iSH-AOK once it has booted this FS
#
setup_common_aok=/opt/AOK/common_AOK/setup_common_env.sh
setup_alpine_scr=/opt/AOK/Alpine/setup_alpine.sh
setup_famdeb_scr=/opt/AOK/FamDeb/setup_famdeb.sh
setup_debian_scr=/opt/AOK/Debian/setup_debian.sh
setup_devuan_scr=/opt/AOK/Devuan/setup_devuan.sh
setup_select_distro_prepare=/opt/AOK/choose_distro/select_distro_prepare.sh
setup_select_distro=/opt/AOK/choose_distro/select_distro.sh
setup_final=/opt/AOK/common_AOK/setup_final_tasks.sh

#
#  When reported what distro is used on Host or Dest FS uses this
#
distro_alpine=Alpine
distro_debian=Debian
distro_devuan=Devuan

deploy_state_na="FS not awailable"       # FS has not yet been created
deploy_state_initializing="initializing" # making FS ready for 1st boot
deploy_state_pre_build="prebuild"        # building FS on buildhost, no details for dest are available
deploy_state_dest_build="dest build"     # building FS on dest, dest details can be gathered
deploy_state_finalizing="finalizing"     # main deploy has happened, now certain to

destfs_select=select
f_destfs_select_hint="$d_build_root"/etc/opt/select_distro

pidfile_do_chroot="$TMPDIR"/aok_do_chroot.pid

#  file alt hostname reads to find hostname
#  the variable has been renamed to
f_hostname_source_fname="$d_aok_etc"/hostname_source_fname

# d_aok_etc="$d_build_root/$d_aok_etc"

f_home_user_replaced="$d_aok_etc"/home_user_replaced
f_home_root_replaced="$d_aok_etc"/home_root_replaced

#
#  For automated logins
#
f_login_default_user="$d_aok_etc"/login-default-username
f_logins_continous="$d_aok_etc"/login-continous

f_hostname_aok_suffix="$d_aok_etc"/hostname-aok-suffix
f_pts_0_as_console="$d_aok_etc"/pts_0_as_console
f_profile_hints="$d_aok_etc"/show_profile_hints

cmd_pigz="$(command -v pigz)"
if [ -z "$cmd_pigz" ] && [ -x /home/linuxbrew/.linuxbrew/bin/pigz ]; then
    cmd_pigz=/home/linuxbrew/.linuxbrew/bin/pigz
fi
