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
#  defaulting to 1. If exit code is 0 this will not exit, just display
#  the error message, then continue.
#
error_msg() {
    em_msg="$1"
    em_exit_code="${2:-1}"
    if [ -z "$em_msg" ]; then
        echo
        echo "error_msg() no param"
        exit 9
    fi
    echo
    echo "ERROR: $em_msg"
    echo
    [ "$em_exit_code" -ne 0 ] && exit "$em_exit_code"
    unset em_msg
    unset em_exit_code
}

msg_script_title() {
    [ -z "$1" ] && error_msg "msg_script_title() no param"
    echo
    echo "***"
    echo "***  $1"
    echo "***"
    echo

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
}

msg_2() {
    [ -z "$1" ] && error_msg "msg_2() no param"
    echo "---  $1"
}

msg_3() {
    [ -z "$1" ] && error_msg "msg_3() no param"
    echo "  -  $1"
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

display_time_elapsed() {
    dte_t_in="$1"
    dte_label="$2"

    dte_mins="$((dte_t_in / 60))"
    dte_seconds="$((dte_t_in - dte_mins * 60))"

    #  Add zero prefix when < 10
    [ "$dte_mins" -gt 0 ] && [ "$dte_mins" -lt 10 ] && dte_mins="0$dte_mins"
    [ "$dte_seconds" -lt 10 ] && dte_seconds="0$dte_seconds"

    echo
    echo "Time elapsed: $dte_mins:$dte_seconds - $dte_label"
    echo
    unset dte_t_in
    unset dte_label
    unset dte_mins
    unset dte_seconds
}

#
#  Some boolean checks
#
is_ish() {
    test -d /proc/ish
}

is_aok_kernel() {
    grep -qi aok /proc/ish/version 2>/dev/null
}

is_debian() {
    test -f "$build_root_d"/etc/debian_version
}

is_alpine() {
    test -f "$build_root_d"/etc/alpine-release
}

is_iCloud_mounted() {
    mount | grep -wq iCloud
}

is_chrooted() {
    bldstat_get "$status_is_chrooted"
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
    result=$(awk -v x="$rel_min" -v y="$rel_this" 'BEGIN{if (x > y) print 1; else print 0}')

    if [ "$result" -eq 1 ]; then
        return 1 # false
    elif [ "$result" -eq 0 ]; then
        return 0 # true
    else
        error_msg "min_release() Failed to compare releases"
    fi
}

#
#  bldstat_xxx is manipulating state files under $aok_content_etc on
#  the dest FS, indicating things like if this is chrooted and so on
#
bldstat_set() {
    # msg_3 "build_staus_set($1)"
    [ -z "$1" ] && error_msg "bldstat_set() no param"
    mkdir -p "$build_status"
    touch "${build_status}/$1"
}

bldstat_get() {
    # msg_3 "build_staus_get($1)"
    [ -z "$1" ] && error_msg "bldstat_get() no param"
    test -f "$build_status/$1"
    bg_exitstatus="$?"
    case "$bg_exitstatus" in

    0)
        unset bg_exitstatus
        return 0
        ;;

    *)
        unset bg_exitstatus
        return 1
        ;;

    esac
}

#  shellcheck disable=SC2120
bldstat_clear() {
    # msg_2 "bldstat_clear($1)"
    if [ -n "$1" ]; then
        bc_fname="$build_status/$1"
        rm -f "$bc_fname"
        # msg_3 "Cleared $bc_fname"
        unset bc_fname
    fi
    if [ "$(find "$build_status"/ 2>/dev/null | wc -l)" -le 1 ]; then
        rm "$build_status" -rf
        msg_2 "Cleared entire $build_status"
    fi
}

bldstat_clear_all() {
    #
    #  Build is done, ensure no leftovers
    #
    rm "$build_status"/* 2>/dev/null
    bldstat_clear
}

distro_name_set() {
    dns_name="$1"
    if [ -z "$dns_name" ]; then
        error_msg "distro_name_set() - no param"
    fi
    echo "$dns_name" >"$build_root_d"/tmp/distro_name
    unset dns_name
}

distro_name_get() {
    if [ ! -f /tmp/distro_name ]; then
        error_msg "/tmo/distro_name not found!"
    fi
    cat /tmp/distro_name
}

start_setup() {
    msg_2 "start_setup()"
    ss_distro_name="$1"
    [ -z "$ss_distro_name" ] && error_msg "start_setup() no distro_name provided"
    ss_vers_info="$2"
    [ -z "$ss_vers_info" ] && error_msg "start_setup() no vers_info provided"

    distro_name_set "$ss_distro_name"
    test -f "$additional_tasks_script" && notification_additional_tasks
    echo

    ! is_iCloud_mounted && iCloud_mount_prompt_notification

    if [ -z "$AOK_TIMEZONE" ]; then
        echo " |  There will be a dialog for        |"
        echo " |  setting timezone after package    |"
        echo " |  updates.                          |"
        echo " |  This is the final step requiring  |"
        echo " |  user intervention. After that the |"
        echo " |  install completes independently.  |"
    fi

    msg_1 "Setting up iSH-AOK FS: $AOK_VERSION for ${ss_distro_name}: $ss_vers_info"

    if [ "$QUICK_DEPLOY" -ne 0 ]; then
        echo
        echo "***  QUICK_DEPLOY=$QUICK_DEPLOY   ***"
    fi

    manual_runbg

    copy_local_bins "$ss_distro_name"

    unset ss_distro_name
    unset ss_vers_info
    # msg_3 "start_setup() done"
}

manual_runbg() {
    #
    #  Only start if not running
    #
    #  shellcheck disable=SC2009
    if ! is_chrooted && ! ps ax | grep -v grep | grep -qw cat; then
	cat /dev/location >/dev/null &
	msg_1 "iSH now able to run in the background"
    fi
}

#  shellcheck disable=SC2120
select_profile() {
    msg_2 "select_profile($1)"
    sp_new_profile="$1"
    if [ -z "$sp_new_profile" ]; then
        error_msg "select_profile() - no param"
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
    # msg_3 "select_profile() done"
}

user_interactions() {
    msg_2 "user_interactions()"

    ! is_iCloud_mounted && should_icloud_be_mounted
    if [ -z "$AOK_TIMEZONE" ]; then
	msg_1 "TZ selection"
        [ -z "$(command -v bash)" ] && apk add bash
        /opt/AOK/common_AOK/usr_local_bin/set-timezone
    fi
    # msg_3 "user_interactions()  - done"
}

create_fs() {
    msg_2 "create_fs($1)"
    cf_tarball="$1"
    [ -z "$cf_tarball" ] && error_msg "cache_fs_image() no taball supplied"
    cf_fs_location="${2:-$build_root_d}"
    cf_verbose="${3:-false}"
    if $cf_verbose; then # verbose mode
        cf_verbose="v"
    else
        cf_verbose=""
    fi
    [ -z "$cf_fs_location" ] && error_msg "no cf_fs_location detected"
    mkdir -p "$cf_fs_location"
    cd "$cf_fs_location" || {
        error_msg "Failed to cd into: $cf_fs_location"
    }

    case "$src_tarball" in
    *alpine*) cf_time_estimate="Should not take that long" ;;
    *) cf_time_estimate="will take up to (iPad 7th: 15 iPad 9th: 7) minutes" ;;
    esac
    msg_3 "Extracting $cf_tarball $cf_time_estimate"
    unset cf_time_estimate

    if test "${cf_tarball#*tgz}" != "$cf_tarball" || test "${cf_tarball#*tar.gz}" != "$cf_tarball"; then
        cf_filter="z"
    else
        msg_3 "detected bzip2 format"
        cf_filter="j"
    fi

    tar "xf${cf_verbose}${cf_filter}" "$cf_tarball" || {
        echo "ERROR: Failed to untar image"
        echo
        echo "Try to remove the cached file and run this again"
        echo "$src_img_cache_d/$src_cf_tarball"
        exit 1
    }
    unset cf_tarball
    unset cf_fs_location
    unset cf_verbose
    unset cf_filter
    # msg_3 "create_fs() done"
}

iCloud_mount_prompt_notification() {
    msg_2 "iCloud_mount_prompt_notification()"
    # abort if not running on iSH
    ! test -d /proc/ish && return

    echo "
 |  There is a prompt about mounting  |
 |  /iCloud, right after repository   |
 |  updates.                          |"
}

should_icloud_be_mounted() {
    msg_2 "should_icloud_be_mounted()"

    if ! is_ish; then
        msg_3 "This is not iSH, skipping /iCloud mount check"
        return
    fi

    if is_iCloud_mounted; then
        msg_3 "was already mounted, returning"
        return
    fi

    # sibm_dlg_app="dialog"
    sibm_dlg_app="whiptail"

    if [ -z "$(command -v "$sibm_dlg_app")" ]; then
        sibm_dependency="$sibm_dlg_app"
        msg_3 "Installing dependency: $sibm_dependency"

        if [ "$sibm_dependency" = "whiptail" ] && is_alpine; then
            # whiptail is in package newt in Alpine
            sibm_dependency="newt"
        fi

        if [ -f "$file_alpine_release" ]; then
            apk add "$sibm_dependency"
        elif [ -f "$file_debian_version" ]; then
            apt install "$sibm_dependency"
        else
            error_msg "Unrecognized distro, aborting"
        fi
        unset sibm_dependency
    fi

    if bldstat_get "$status_prebuilt_fs" && bldstat_get "$status_is_chrooted"; then
        msg_3 "Pre-building FS - task delayed until final step"
        unset sibm_dlg_app
        return
    fi
    sibm_text="Do you want to mount /iCloud now?"
    # --topleft \
    "$sibm_dlg_app" \
        --title "Mount /iCloud" \
        --yesno "$sibm_text" 0 0

    sibm_exitstatus=$?

    if [ "$sibm_exitstatus" -eq 0 ]; then
        mount -t ios x /iCloud
    fi
    unset sibm_dlg_app
    unset sibm_text
    unset sibm_exitstatus
    msg_3 "should_icloud_be_mounted()  done"
}

#
#  Auto sudo
#
run_as_root() {
    #  if started by user account, execute again as root
    if [ "$(whoami)" != "root" ]; then
        msg_2 "Executing $0 as root"
        # using $0 instead of full path makes location not hardcoded
        if ! sudo "$0" "$@"; then
            error_msg "Failed to sudo run: $0"
        fi
        # terminate the user initiated instance
        exit 0
    fi
}

#
#  Busybox wget cant hanle redirects, this installs real wget if needbe
#
ensure_usable_wget() {
    msg_3 "ensure_usable_wget()"
    #  shellcheck disable=SC2010
    if ls -l "$(command -v wget)" | grep -q busybox; then
        error_msg "You need to install a real wget, busybox does not handle redirects"
    fi
    # msg_3 "ensure_usable_wget()  done"
}

copy_local_bins() {
    msg_2 "copy_local_bins($1)"
    clb_base_dir="$1"
    if [ -z "$clb_base_dir" ]; then
        error_msg "call to copy_local_bins() without param!"
    fi

    # msg_1 "Copying /usr/local stuff from $clb_base_dir"

    clb_src_dir="${aok_content}/${clb_base_dir}/usr_local_bin"
    if [ -z "$(find "$clb_src_dir" -type d -empty)" ]; then
        msg_3 "Add $clb_base_dir AOK-FS stuff to /usr/local/bin"
        mkdir -p /usr/local/bin
        cp "$clb_src_dir"/* /usr/local/bin
        chmod +x /usr/local/bin/*
    fi

    clb_src_dir="${aok_content}/${clb_base_dir}/usr_local_sbin"
    if [ -z "$(find "$clb_src_dir" -type d -empty)" ]; then
        msg_3 "Add $clb_base_dir AOK-FS stuff to /usr/local/sbin"
        mkdir -p /usr/local/sbin
        cp "$clb_src_dir"/* /usr/local/sbin
        chmod +x /usr/local/sbin/*
    fi
    unset clb_base_dir
    unset clb_src_dir
    # msg_3 "copy_local_bins() done"
}

copy_skel_files() {
    csf_dest="$1"
    if [ -z "$csf_dest" ]; then
        error_msg "copy_skel_files() needs a destination param"
    fi
    cp -r /etc/skel/. "$csf_dest"
    cd "$csf_dest" || {
        error_msg "Failed to cd into: $csf_dest"
    }

    ln -sf .bash_profile .bashrc

    unset csf_dest
}

notification_additional_tasks() {
    # msg_2 "notification_additional_tasks()"
    if [ -f "$additional_tasks_script" ]; then
        echo "At the end of the install, this will be run:"
        echo "--------------------"
        cat "$additional_tasks_script"
        echo "--------------------"
        echo
    fi
    # msg_3 "notification_additional_tasks() done"
}

run_additional_tasks_if_found() {
    msg_2 "run_additional_tasks_if_found()"
    if [ -x "$additional_tasks_script" ]; then
        msg_1 "Running additional setup tasks"
        "$additional_tasks_script" && rm "$additional_tasks_script"
        echo
    fi
    # msg_3 "run_additional_tasks_if_found()  done"
}

replace_home_dirs() {
    if [ -n "$HOME_DIR_USER" ]; then
        [ ! -f "$HOME_DIR_USER" ] && error_msg "USER_HOME_DIR file not found: $HOME_DIR_USER"
        [ -z "$USER_NAME" ] && error_msg "USER_HOME_DIR defined, but not USER_NAME"
        msg_2 "Replacing /home/$USER_NAME"
        cd "/home" || error_msg "Failed cd /home"
        rm -rf "$USER_NAME"
        tar xfz "$HOME_DIR_USER" || error_msg "Failed to extract USER_HOME_DIR"
    fi

    if [ -n "$HOME_DIR_ROOT" ]; then
        [ ! -f "$HOME_DIR_ROOT" ] && error_msg "ROOT_HOME_DIR file not found: $HOME_DIR_ROOT"
        msg_2 "Replacing /root"
        rm /root -rf
        cd /
        tar xfz "$HOME_DIR_ROOT" || error_msg "Failed to extract USER_HOME_DIR"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

#
#  To make things simple, this is the expected location for AOK-Filesystem-tools
#  both on build and iSH systems
#  Due to necesity, this file needs to be sourced as: . /opt/AOK/toold/utils.sh
#  Please do not use the abs path /opt/AOK for anything else, in all other
#  references, use $aok_content
#  If this location is ever changed, this will keep the changes in the
#  code to a minimum.
#
aok_content="/opt/AOK"

#
#  Import settings
#
#  shellcheck disable=SC1091
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
# fi

#
#  Used for keeping track of deploy / chroot status
#
aok_content_etc="/etc$aok_content"

#
#  Detecting build environments
#  0 = other, not able to chroot to complete image
#  1 = iSH
#  2 = Linux (x86)
#
if is_ish; then
    build_env=1
elif uname -a | grep -qi linux && uname -a | grep -q x86; then
    build_env=2
else
    build_env=0 # chroot not possible
fi

#
#  Locations for "other" stuff
#

#  Location for src images
src_img_cache_d="/tmp/cache_AOK_images"

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

target_alpine="Alpine"
target_debian="Debian"
target_devuan="Devuan"
target_select="select"

#
#  Statuses are files put in place in $aok_content_etc on the destination FS
#  to indicate various states of progress
#

#  This is chrooted
status_is_chrooted="is_chrooted"

#  Indicator this is an env being built
status_being_built="env_beeing_built"
#
#  Select distro has been prepared, ie the prepare sterp does not to be
#  run during deploy
#
status_select_distro_prepared="select_distro_prepared"

#
#  Hint to Debian to clear out the arround 50MB of apt cache
#  in order for the FS to be smaller when it is compressed
#
status_prebuilt_fs="prebuilt_fs_first_boot"

#  Locations for building File systems
build_base_d="/tmp/AOK"

#
#  temp value until we know if this is dest FS, so that build_root_d can
#  be selected
#
build_status_raw="$aok_content_etc"

#
#  status_being_built and build_status, used by bldstat_get()
#  must be defined before this
#
if is_chrooted; then
    # msg_3 "This is chrooted"
    build_root_d=""
elif test -f "$build_status_raw/$status_being_built"; then
    # msg_3 "This is running on dest platform"
    build_root_d=""
else
    # msg_3 "Not chrooted, not dest platform"
    build_root_d="$build_base_d/FS"
fi

#  Now the proper value can be set
build_status="${build_root_d}${build_status_raw}"

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
setup_alpine_final="$aok_content"/Alpine/setup_alpine_final_tasks.sh
setup_debian_scr="$aok_content"/Debian/setup_debian.sh
setup_debian_final="$aok_content"/Debian/setup_debian_final_tasks.sh
setup_devuan_scr="$aok_content"/Devuan/setup_devuan.sh
setup_devuan_final="$aok_content"/Devuan/setup_devuan_final_tasks.sh
setup_select_distro_prepare="$aok_content"/choose_distro/select_distro_prepare.sh
setup_select_distro="$aok_content"/choose_distro/select_distro.sh
