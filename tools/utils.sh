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
#  Used for keeping track of deploy / chroot status
#
aok_content_etc="/etc$aok_content"

#
#  Import settings
#

#  shellcheck disable=SC1091
. "$aok_content"/AOK_VARS || exit 1

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
#  Some boolean checks
#
is_ish() {
    test -d /proc/ish
}

is_aok_kernel() {
    grep -qi aok /proc/ish/version 2>/dev/null
}

is_debian() {
    test -f /etc/debian_version
}

is_alpine() {
    test -f /etc/alpine-release
}

is_iCloud_mounted() {
    mount | grep -wq iCloud
}

is_chrooted() {
    bldstat_get "$status_is_chrooted"
}

#
#  Display warning message indicating that errors displayed during
#  openrc actions can be ignored, and are not to be read as failures in
#  the deploy procedure.
#
openrc_might_trigger_errors() {
    echo
    echo "You might see a few errors printed as services are activated."
    echo "The iSH family doesn't fully support openrc yet, but the important parts work!"
    echo
}

display_time_elapsed() {
    dte_t_in="$1"
    dte_label="$2"

    dte_mins="$((dte_t_in / 60))"
    dte_seconds="$((dte_t_in - dte_mins * 60))"
    echo
    echo "Time elapsed: $dte_mins:$dte_seconds - $dte_label"
    echo
    unset dte_t_in
    unset dte_label
    unset dte_mins
    unset dte_seconds
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
    # msg_3 "bldstat_clear($1)"
    if [ -n "$1" ]; then
        bc_fname="$build_status/$1"
        rm -f "$bc_fname"
        # msg_3 "Cleared $bc_fname"
        unset bc_fname
    fi
    if [ "$(find "$build_status"/ 2>/dev/null | wc -l)" -le 1 ]; then
        rm "$build_status" -rf
        msg_3 "Cleared entire $build_status"
    fi
}

bldstat_clear_all() {
    #
    #  Build is done, ensure no leftovers
    #
    rm "$build_status"/* 2>/dev/null
    bldstat_clear
}

copy_profile() {
    cp_src="$1"
    [ -z "$cp_src" ] && error_msg "copy_profile() no param"
    [ ! -f "$cp_src" ] && error_msg "copy_profile() src not found:$cp_src"
    cp_profile="$build_root_d"/etc/profile
    msg_3 "copying profile: $cp_src to: $cp_profile"
    cp "$cp_src" "$cp_profile"
    chmod 755 "$cp_profile"
    unset cp_src
    unset cp_profile
    # msg_3 "copy_profile() done"
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
    msg_3 "select_profile() done"
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
    cd "$cf_fs_location" || exit 1
    msg_2 "Extracting $cf_tarball"
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
 |  There is a prompt about mounting   |
 |  /iCloud, right after the package   |
 |  update.                            |"

    if [ -n "$AOK_TIMEZONE" ]; then
        echo " | After that, the rest of the install |"
        echo " | runs without need for interactions. |"
    fi
}

should_icloud_be_mounted() {
    # abort if not running on iSH
    ! test -d /proc/ish && return

    msg_2 "should_icloud_be_mounted()"
    if ! is_iCloud_mounted; then
        if [ -z "$(command -v whiptail)" ]; then
            if [ -f "$file_alpine_release" ]; then
                apk add newt # contains whiptail
            elif [ -f "$file_debian_version" ]; then
                apt install whiptail
            else
                error_msg "Unrecognized distro, aborting"
            fi
        fi
        sibm_text="Do you want to mount iCloud now?"
        whiptail \
            --topleft \
            --title "Mount iCloud" \
            --yesno "$sibm_text" 0 0

        sibm_exitstatus=$?

        if [ "$sibm_exitstatus" -eq 0 ]; then
            mount -t ios x /iCloud
        fi
        unset sibm_text
        unset sibm_exitstatus
    fi
    # msg_3 "should_icloud_be_mounted()  done"
}

start_setup() {
    msg_2 "start_setup()"
    ss_distro_name="$1"
    [ -z "$ss_distro_name" ] && error_msg "start_setup() no ss_distro_name provided"
    ss_vers_info="$2"
    [ -z "$ss_vers_info" ] && error_msg "start_setup() no ss_vers_info provided"

    test -f "$additional_tasks_script" && notification_additional_tasks

    ! is_iCloud_mounted && iCloud_mount_prompt_notification

    msg_1 "Setting up iSH-AOK FS: $AOK_VERSION for ${ss_distro_name}: $ss_vers_info"

    if [ "$QUICK_DEPLOY" -ne 0 ]; then
        echo
        echo "***  QUICK_DEPLOY=$QUICK_DEPLOY   ***"
    fi

    if ! is_chrooted; then
        cat /dev/location >/dev/null &
        msg_3 "iSH now able to run in the background"
    fi

    copy_local_bins "$ss_distro_name"
    unset ss_distro_name
    unset ss_vers_info
    # msg_3 "start_setup() done"
}

copy_local_bins() {
    msg_2 "copy_local_bins($1)"
    clb_src_dir="$1"
    if [ -z "$clb_src_dir" ]; then
        error_msg "call to copy_local_bins() without param!"
    fi

    msg_1 "Copying /usr/local stuff for $clb_src_dir"

    msg_3 "Add $clb_src_dir AOK-FS stuff to /usr/local/bin"
    mkdir -p /usr/local/bin
    cp "$aok_content"/"$clb_src_dir"/usr_local_bin/* /usr/local/bin
    chmod +x /usr/local/bin/*

    msg_3 "Add $clb_src_dir AOK-FS stuff to /usr/local/sbin"
    mkdir -p /usr/local/sbin
    cp "$aok_content"/"$clb_src_dir"/usr_local_sbin/* /usr/local/sbin
    chmod +x /usr/local/sbin/*
    echo
    unset clb_src_dir
    # msg_3 "copy_local_bins() done"
}

notification_additional_tasks() {
    msg_2 "notification_additional_tasks()"
    if [ -f "$additional_tasks_script" ]; then
        msg_2 "notification_additional_tasks()"
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
        echo
        "$additional_tasks_script" && rm "$additional_tasks_script"
        echo
    fi
    # msg_3 "run_additional_tasks_if_found()  done"
}

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
debian_src_tb="$(echo "$DEBIAN_SRC_IMAGE" | grep -oE '[^/]+$')"

#
#  Extract the release/branch/major version, from the requested Alpine,
#  gives something like 3.14
if [ "$ALPINE_VERSION" = "edge" ]; then
    alpine_src_tb="alpine-minirootfs-20221110-x86.tar.gz"
    alpine_release="$ALPINE_VERSION"
    _vers="$ALPINE_VERSION"
    # https://dl-cdn.alpinelinux.org/alpine/edge/releases/x86/alpine-minirootfs-20190227-x86.tar.gz

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
alpine_tb="Alpine-${ALPINE_VERSION}-iSH-AOK-$AOK_VERSION"
select_distro_tb="SelectDistro-iSH-AOK-$AOK_VERSION"
debian_tb="Debian-iSH-AOK-$AOK_VERSION"
#  alternate name, using the name of the tarball as prefix
#  more informative, but is a bit long to display in iOS
# debian_tb="$(echo "$DEBIAN_SRC_IMG" | cut -d. -f1)-iSH-AOK-$AOK_VERSION"

target_alpine="Alpine"
target_debian="Debian"
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
    build_root_d=""
    # msg_3 "This is chrooted"
elif test -f "$build_status_raw/$status_being_built"; then
    build_root_d=""
    # msg_3 "This is running on dest platform"
else
    # msg_3 "Not chrooted, not dest platform"
    build_root_d="$build_base_d/iSH-AOK-FS"
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
#  After all packages are installed, if /bin/login was something other
#  than a soft-link to /bin/busybox, it will be renamed to this,
#  so it can be selected later.
#
login_original="/bin/login.alpine"

#
#  Either run this script chrooted if the host OS supports it, or run it
#  inside iSH-AOK once it has booted this FS
#
setup_common_aok="$aok_content"/common_AOK/setup_common_env.sh
setup_alpine_scr="$aok_content"/Alpine/setup_alpine.sh
setup_alpine_final="$aok_content"/Alpine/setup_alpine_final_tasks.sh
setup_debian_scr="$aok_content"/Debian/setup_debian.sh
setup_select_distro_prepare="$aok_content"/choose_distro/select_distro_prepare.sh
setup_select_distro="$aok_content"/choose_distro/select_distro.sh

# =====================================================================
#
#  Local overrides, ignored by git. They will be appended to build_env
#  for the deployed image if found.
#  This is intended for debuging and testing, and appends the same
#  override file as in AOK_VARS, to ensure overrides to settings here
#  take effect.
#  This way on the deployed platform it will be easy to spot what
#  temp/devel settings was used in the build process.
#
# =====================================================================

###  override handling  ###

local_overrides="${aok_content}/.AOK_VARS"

#  shellcheck disable=SC1090
[ -f "$local_overrides" ] && . "$local_overrides"
unset local_overrides
