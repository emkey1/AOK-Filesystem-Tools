#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#  shellcheck disable=SC2034,SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
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
    fi

    echo
    echo "ERROR: $_em_msg"
    echo
    [ -n "$LOG_FILE" ] && echo "ERROR: $_em_msg" >>"$LOG_FILE" 2>&1
    [ "$_em_exit_code" != "no_exit" ] && exit "$_em_exit_code"
    unset _em_msg
    unset _em_exit_code
}

debug_sleep() {
    # msg_2 "debug_sleep($1,$2)"
    _ds_msg="$1"
    [ -z "$_ds_msg" ] && error_msg "debug_sleep() - no msg param"

    _ds_t_slp="$2"
    [ -z "$_ds_t_slp" ] && error_msg "debug_sleep($msg) - no time param"

    msg_1 "$_ds_msg - ${_ds_t_slp}s sleep"
    sleep "$_ds_t_slp"

    unset _ds_msg
    unset _ds_t_slp
    # msg_3 "debug_sleep() - done"
}

#
#  The msg_ functions are ordered, lower number infers more important updates
#  so they should stand out more
#
msg_1() {
    [ -z "$1" ] && error_msg "msg_1() no param"
    echo
    echo "===  $1  ==="
    echo
    [ -n "$LOG_FILE" ] && echo "[$(date)] ===  $1  ===" >>"$LOG_FILE" 2>&1
}

msg_2() {
    [ -z "$1" ] && error_msg "msg_2() no param"
    echo "---  $1"
    [ -n "$LOG_FILE" ] && echo "[$(date)] ---  $1" >>"$LOG_FILE" 2>&1
}

msg_3() {
    [ -z "$1" ] && error_msg "msg_3() no param"
    echo "  -  $1"
    [ -n "$LOG_FILE" ] && echo "[$(date)]   -  $1" >>"$LOG_FILE" 2>&1
}

msg_script_title() {
    [ -z "$1" ] && error_msg "msg_script_title() no param"
    echo
    echo "***"
    echo "***  $1"
    echo "***"
    echo

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
    msg_2 "initiate_deploy()"
    #
    #  If either is not found, we dont know what to install and how
    #
    # [ ! -f "$f_build_type" ] && error_msg "$f_build_type missing, unable to deploy"

    _ss_distro_name="$1"
    [ -z "$_ss_distro_name" ] && error_msg "initiate_deploy() no distro_name provided"
    _ss_vers_info="$2"
    [ -z "$_ss_vers_info" ] && error_msg "initiate_deploy() no vers_info provided"

    # buildtype_set "$_ss_distro_name"
    if [ -n "$FIRST_BOOT_ADDITIONAL_TASKS" ]; then
        msg_2 "At the end of the install, additioal tasks will be run:"
        echo "--------------------"
        echo "$FIRST_BOOT_ADDITIONAL_TASKS"
        echo "--------------------"
    fi
    echo

    msg_1 "Setting up iSH-AOK FS: $AOK_VERSION for ${_ss_distro_name}: $_ss_vers_info"

    if [ "$QUICK_DEPLOY" -ne 0 ]; then
        echo
        echo "***  QUICK_DEPLOY=$QUICK_DEPLOY   ***"
    fi

    manual_runbg

    copy_local_bins "$_ss_distro_name"

    unset _ss_distro_name
    unset _ss_vers_info
    # msg_3 "initiate_deploy() done"
}

#  shellcheck disable=SC2120
set_new_etc_profile() {
    msg_2 "set_new_etc_profile($1)"
    sp_new_profile="$1"
    if [ -z "$sp_new_profile" ]; then
        error_msg "set_new_etc_profile() - no param"
    fi

    #
    #  Avoid file replacement whilst running doesnt overwrite the
    #  previous script without first removing it, leaving a garbled file
    #
    rm "$build_root_d"/etc/profile

    cp -a "$sp_new_profile" "$build_root_d"/etc/profile

    #
    #  Normaly profile is sourced, but in order to be able to directly
    #  run it if manually triggering a deploy, make it executable
    #
    chmod 744 "$build_root_d"/etc/profile
    unset sp_new_profile
    # msg_3 "set_new_etc_profile() done"
}

create_fs() {
    #
    #  Extract a $1 tarball at $2 location - verbose flag $3
    #
    msg_2 "create_fs()"
    _cf_tarball="$1"
    [ -z "$_cf_tarball" ] && error_msg "cache_fs_image() no taball supplied"
    _cf_fs_location="${2:-$build_root_d}"
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

    case "$src_tarball" in
    *alpine*) _cf_time_estimate="Should not take that long" ;;
    *) _cf_time_estimate="will take a while (iPad 5th:14 iPad 7th:6 minutes)" ;;
    esac
    msg_3 "Extracting $_cf_tarball $_cf_time_estimate"
    unset _cf_time_estimate

    if test "${_cf_tarball#*tgz}" != "$_cf_tarball" || test "${_cf_tarball#*tar.gz}" != "$_cf_tarball"; then
        _cf_filter="z"
    else
        msg_3 "detected bzip2 format"
        _cf_filter="j"
    fi

    tar "xf${_cf_verbose}${_cf_filter}" "$_cf_tarball" || {
        echo "ERROR: Failed to untar image"
        echo
        echo "Try to remove the cached file and run this again"
        echo "$src_img_cache_d/$src_tarball"
        exit 1
    }
    deploy_state_set "$deploy_state_initializing"

    unset _cf_tarball
    unset _cf_fs_location
    unset _cf_verbose
    unset _cf_filter
    # msg_3 "create_fs() done"
}

display_time_elapsed() {
    _dte_t_in="$1"
    _dte_label="$2"

    _dte_mins="$((_dte_t_in / 60))"
    _dte_seconds="$((_dte_t_in - _dte_mins * 60))"

    #  Add zero prefix when < 10
    [ "$_dte_mins" -gt 0 ] && [ "$_dte_mins" -lt 10 ] && _dte_mins="0$_dte_mins"
    [ "$_dte_seconds" -lt 10 ] && _dte_seconds="0$_dte_seconds"

    echo
    echo "Time elapsed: $_dte_mins:$_dte_seconds - $_dte_label"
    echo
    unset _dte_t_in
    unset _dte_label
    unset _dte_mins
    unset _dte_seconds
}

copy_local_bins() {
    msg_2 "copy_local_bins($1)"
    _clb_base_dir="$1"
    if [ -z "$_clb_base_dir" ]; then
        error_msg "call to copy_local_bins() without param!"
    fi

    # msg_1 "Copying /usr/local stuff from $_clb_base_dir"

    _clb_src_dir="${aok_content}/${_clb_base_dir}/usr_local_bin"
    if [ -z "$(find "$_clb_src_dir" -type d -empty)" ]; then
        msg_3 "Add $_clb_base_dir AOK-FS stuff to /usr/local/bin"
        mkdir -p /usr/local/bin
        cp "$_clb_src_dir"/* /usr/local/bin
        chmod +x /usr/local/bin/*
    fi

    _clb_src_dir="${aok_content}/${_clb_base_dir}/usr_local_sbin"
    # if [ -z "$(find "$_clb_src_dir" -type d -empty)" ]; then
    if [ -d "$_clb_src_dir" ]; then
        msg_3 "Add $_clb_base_dir AOK-FS stuff to /usr/local/sbin"
        mkdir -p /usr/local/sbin
        cp "$_clb_src_dir"/* /usr/local/sbin
        chmod +x /usr/local/sbin/*
    fi
    unset _clb_base_dir
    unset _clb_src_dir
    # msg_3 "copy_local_bins() done"
}

copy_skel_files() {
    _csf_dest="$1"
    if [ -z "$_csf_dest" ]; then
        error_msg "copy_skel_files() needs a destination param"
    fi
    cp -r /etc/skel/. "$_csf_dest"
    cd "$_csf_dest" || {
        error_msg "Failed to cd into: $_csf_dest"
    }

    ln -sf .bash_profile .bashrc

    unset _csf_dest
}

set_initial_login_mode() {
    if [ -n "$INITIAL_LOGIN_MODE" ]; then
        #
        #  Now that final_tasks have run as root, the desired login method
        #  can be set.
        #
        msg_2 "Using defined login method. It will be used next time App is run"
        /usr/local/bin/aok -l "$INITIAL_LOGIN_MODE"
    else
        msg_2 "No login mode defined, disabling console login"
        /usr/local/bin/aok -l disable
    fi
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
#   chroot handling
#
#  Theese are convenience hints that can be set in order for
#  scipts to keep
#
#---------------------------------------------------------------

this_fs_is_chrooted() {
    #  Check this _ACTUAL_ fs
    [ -n "$DEBUG_BUILD" ] && msg_2 "this_fs_is_chrooted() [$f_this_fs_is_chrooted_raw]"
    [ -f "$f_this_fs_is_chrooted_raw" ]
}
dest_fs_is_chrooted() {
    [ -n "$DEBUG_BUILD" ] && msg_2 "dest_fs_is_chrooted() [$f_this_fs_is_chrooted]"
    [ -f "$f_this_fs_is_chrooted" ]
}

destfs_set_is_chrooted() {
    # msg_2 "destfs_set_is_chrooted(()"
    [ -n "$DEBUG_BUILD" ] && msg_1 "destfs_set_is_chrooted() [$f_this_fs_is_chrooted]"
    if [ "$f_this_fs_is_chrooted" = "$f_this_fs_is_chrooted_raw" ]; then
        msg_2 "f_this_fs_is_chrooted same as f_this_fs_is_chrooted_raw"
        msg_3 "$f_this_fs_is_chrooted"
        error_msg "flagging dest FS as chrooted NOT possible!"
    fi
    mkdir -p "$(dirname "$f_this_fs_is_chrooted")"
    touch "$f_this_fs_is_chrooted"
    # msg_3 "destfs_set_is_chrooted(() - done"
}

destfs_clear_chrooted() {
    # msg_2 "destfs_clear_chrooted(()"

    if [ "$f_this_fs_is_chrooted" = "$f_this_fs_is_chrooted_raw" ]; then
        msg_2 "f_this_fs_is_chrooted same as f_this_fs_is_chrooted_raw"
        msg_3 "$f_this_fs_is_chrooted"
        error_msg "clearing dest FS as chrooted NOT possible!"
    fi

    if [ -f "$f_this_fs_is_chrooted" ]; then
        rm "$f_this_fs_is_chrooted"
    else
        error_msg "destfs_clear_chrooted() - could not find chroot indicator"
    fi
    # msg_3 "destfs_clear_chrooted(() - done"
}

#---------------------------------------------------------------
#
#   Related to custom settings
#
#---------------------------------------------------------------

replace_home_dirs() {
    if [ -n "$HOME_DIR_USER" ]; then
        if [ -f "$HOME_DIR_USER" ]; then
            [ -z "$USER_NAME" ] && error_msg "USER_HOME_DIR defined, but not USER_NAME"
            msg_2 "Replacing /home/$USER_NAME"
            cd "/home" || error_msg "Failed cd /home"
            rm -rf "$USER_NAME"
            tar xfz "$HOME_DIR_USER" || error_msg "Failed to extract USER_HOME_DIR"
	else
	    error_msg "USER_HOME_DIR file not found: $HOME_DIR_USER" "no_exit"
	fi
    fi

    if [ -n "$HOME_DIR_ROOT" ]; then
        if [ -f "$HOME_DIR_ROOT" ]; then
            msg_2 "Replacing /root"
            rm /root -rf
            cd / || error_msg "Failed to cd into: /"
            tar xfz "$HOME_DIR_ROOT" || error_msg "Failed to extract USER_HOME_DIR"
	else
	    error_msg "ROOT_HOME_DIR file not found: $HOME_DIR_ROOT" "no_exit"
	fi
    fi
}


#---------------------------------------------------------------
#
#   Host FS
#
#---------------------------------------------------------------

hostfs_is_alpine() {
    test -f /etc/alpine-release
}

hostfs_is_debian() {
    test -f /etc/debian_version && ! destfs_is_devuan
}

hostfs_is_devuan() {
    test -f "/etc/devuan_version"
}

hostfs_detect() {
    #
    #
    #  Since a select env also looks like Alpine, this must fist
    #  test if it matches the test criteria
    #
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
#---------------------------------------------------------------

destfs_is_devuan() {
    test -f "$build_root_d"/etc/devuan_version
}

destfs_is_debian() {
    test -f "$build_root_d"/etc/debian_version && ! destfs_is_devuan
}

destfs_is_alpine() {
    ! destfs_is_select && test -f "$file_alpine_release"
}

destfs_is_select() {
    [ -f "$destfs_select_hint" ]
}

destfs_detect() {
    #
    #  Since a select env also looks like Alpine, this must fist
    #  test if it matches the test criteria
    #
    if destfs_is_alpine; then
        echo "$distro_alpine"
    elif destfs_is_select; then
        echo "$destfs_select"
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

    mkdir -p "$(dirname "$f_deploy_state")"
    echo "$_state" >"$f_deploy_state"

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
    _state="$(cat "$f_deploy_state" 2>/dev/null)"
    if [ -z "$_state" ]; then
        # This will only be logged, that depends on LOG_FILE being set
        msg_1 "deploy_state_get() did not find anything in [$f_deploy_state]" >/dev/null
        echo ""
    else
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

deploy_state_clear() {
    msg_2 "deploy_state_clear()"

    rm "$f_deploy_state"

    msg_3 "deploy_state_clear() - done"
}

deploy_starting() {
    if deploy_state_is_it "$deploy_state_initializing"; then
        deploy_state_set "$deploy_state_dest_build"
    elif ! deploy_state_is_it "$deploy_state_pre_build"; then
        error_msg "Dest FS in an unknown state [$(deploy_state_get)], can't continue"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

#
#  Only use if you want low-level debugging, in most cases not helpfull
#
# DEBUG_BUILD=1

while [ -f "/run/fixdev.pid" ]; do
    msg_3 "Waiting for fix_dev to complete"
    sleep 1
done

#
#  Might be activated in AOK_VARS or .AOK_VARS
#  initial state is disabled
#
LOG_FILE=""

#
#  To make things simple, this is the expected location for AOK-Filesystem-tools
#  both on build platforms and dest systems
#  Due to necesity, this file needs to be sourced as: . /opt/AOK/toold/utils.sh
#  Please do not use the abs path /opt/AOK for anything else, in all other
#  references, use $aok_content
#  If this location is ever changed, this will keep the changes in the
#  code to a minimum.
#
aok_content="/opt/AOK"

#
#  Import default settings
#
#  shellcheck source=/opt/AOK/AOK_VARS
. "$aok_content"/AOK_VARS || exit 1

#
#  Read .AOK_VARS if pressent, allowing it to overide AOK_VARS
#
# if [ "$(echo "$0" | sed 's/\// /g' | awk '{print $NF}')" = "build_fs" ]; then
conf_overrides="${aok_content}/.AOK_VARS"
if [ -f "$conf_overrides" ]; then
    # msg_2 "Found .AOK_VARS"
    #  shellcheck disable=SC1090
    . "$conf_overrides"
fi
unset conf_overrides

TMPDIR="${TMPDIR:-/tmp}"

#
#  temp value until we know if this is dest FS, so that build_root_d can
#  be selected
#
build_ro1t_d=""
#
#  Locations build host for working on a client FS
#
build_base_d="$TMPDIR/AOK"

#
#  Used for keeping track of deploy / chroot status
#
aok_content_etc="/etc$aok_content"

f_this_fs_is_chrooted_raw="/etc/opt/this_fs_is_chrooted"
f_deploy_state_raw="${aok_content_etc}/deploy_state"

if [ -n "$DEBUG_BUILD" ]; then
    echo ">>> --- Raw states"
    echo ">>> this is f_this_fs_is_chrooted [$f_this_fs_is_chrooted_raw] f_deploy_state [$f_deploy_state_raw]"
fi

if [ -f "$f_this_fs_is_chrooted_raw" ] || [ -f "$f_deploy_state_raw" ]; then
    [ -n "$DEBUG_BUILD" ] && msg_3 "running inside dest FS"
else
    build_root_d="$build_base_d/FS"
    [ -n "$DEBUG_BUILD" ] && msg_3 "running on build host FS"
fi

f_this_fs_is_chrooted="${build_root_d}${f_this_fs_is_chrooted_raw}"
f_deploy_state="${build_root_d}${f_deploy_state_raw}"

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

if [ -n "$DEBUG_BUILD" ]; then
    echo ">>> === defined states"
    echo ">>> f_this_fs_is_chrooted [$f_this_fs_is_chrooted]  f_deploy_state [$f_deploy_state]"
    echo ">>> build_env [$build_env]"
fi

#
#  Locations for "other" stuff
#

#  Location for src images
src_img_cache_d="$TMPDIR/cache_AOK_images"

#
#  If this is built on an iSH node, and iCloud is mounted, the image is
#  copied to this location
#
icloud_archive_d="/iCloud/AOK_Archive"

#
#  Names of the rootfs tarballs used for initial population of FS
#
debian_src_tb="$(echo "$DEBIAN_SRC_IMAGE" | cut -d'?' -f1 | grep -oE '[^/]+$')"
devuan_src_tb="$(echo "$DEVUAN_SRC_IMAGE" | cut -d'?' -f1 | grep -oE '[^/]+$')"

#
#  Extract the release/branch/major version, from the requested Alpine,
#  gives something like 3.14
#
if [ "$ALPINE_VERSION" = "edge" ]; then
    alpine_src_tb="alpine-minirootfs-20230329-x86.tar.gz"
    alpine_release="$ALPINE_VERSION"
    _vers="$ALPINE_VERSION"
else
    alpine_src_tb="alpine-minirootfs-${ALPINE_VERSION}-x86.tar.gz"
    alpine_release="$(echo "$ALPINE_VERSION" | cut -d"." -f 1,2)"
    _vers="v$alpine_release"
fi
alpine_src_image="https://dl-cdn.alpinelinux.org/alpine/$_vers/releases/x86/$alpine_src_tb"
unset _vers

#
#  Names of the generated distribution tarballs, no ext, that is ecided
#  upon during compression
#
alpine_tb="AOK-Alpine-${ALPINE_VERSION}-$AOK_VERSION"
select_distro_tb="AOK-SelectDistro-$AOK_VERSION"
debian_tb="AOK-Debian-10-$AOK_VERSION"
devuan_tb="AOK-Devuan-4-$AOK_VERSION"

#  Where to find native FS version
file_alpine_release="$build_root_d"/etc/alpine-release
file_debian_version="$build_root_d"/etc/debian_version

#  Placeholder, to store what version of AOK that was used to build FS
file_aok_release="$build_root_d"/etc/aok-release

#
#  First boot additional tasks to be run, defined in AOK_VARS,
#  FIRST_BOOT_ADDITIONAL_TASKS
#
additional_tasks_script="$build_root_d/opt/additional_tasks"

#
#  Either run this script chrooted if the host OS supports it, or run it
#  inside iSH-AOK once it has booted this FS
#
setup_common_aok="$aok_content"/common_AOK/setup_common_env.sh
setup_alpine_scr="$aok_content"/Alpine/setup_alpine.sh
setup_debian_scr="$aok_content"/Debian/setup_debian.sh
setup_devuan_scr="$aok_content"/Devuan/setup_devuan.sh
setup_select_distro_prepare="$aok_content"/choose_distro/select_distro_prepare.sh
setup_select_distro="$aok_content"/choose_distro/select_distro.sh
setup_final="$aok_content"/common_AOK/setup_final_tasks.sh

#
#  When reported what distro is used on Host or Dest FS uses this
#
distro_alpine="Alpine"
distro_debian="Debian"
distro_devuan="Devuan"

deploy_state_na="FS not awailable"       # FS has not yet been created
deploy_state_initializing="initializing" # making FS ready for 1st boot
deploy_state_pre_build="prebuild"        # building FS on buildhost, no details for dest are available
deploy_state_dest_build="dest build"     # building FS on dest, dest details can be gathered
deploy_state_finalizing="finalizing"     # main deploy has happened, now certain to

destfs_select="select"
destfs_select_hint="$build_root_d"/etc/opt/select_distro

pidfile_do_chroot="$TMPDIR/aok_do_chroot.pid"
