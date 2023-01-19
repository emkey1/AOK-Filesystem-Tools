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
#
aok_content="/opt/AOK"
aok_content_etc="/etc/$aok_content"

#  shellcheck disable=SC1091
. "$aok_content"/AOK_VARS || exit 1

#
#  Display an error message, second optional param is exit code,
#  defaulting to 1. If exit code is 0 this will not exit, just display
#  the error message, then continue.
#
error_msg() {
    msg="$1"
    exit_code="${2:-1}"
    if [ -z "$msg" ]; then
        echo
        echo "error_msg() no param"
        exit 9
    fi
    echo
    echo "ERROR: $msg"
    echo
    [ "$exit_code" -ne 0 ] && exit "$exit_code"
    unset msg
    unset exit_code
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

#
#  Warning message displayed, indicating errors during openrc actions
#  can be ignored, and are not to be read as failures in the deploy
#  procedure
#
openrc_might_trigger_errors() {
    echo
    echo "You might see a few errors printed as services are activated."
    echo "The iSH family doesn't fully support openrc yet, but the important parts work!"
    echo
}

display_time_elapsed() {
    t_in="$1"
    label="$2"

    mins="$((t_in / 60))"
    seconds="$((t_in - mins * 60))"
    echo
    echo "Time elapsed: $mins:$seconds - $label"
    echo
    unset t_in
    unset label
    unset mins
    unset seconds
}

#
#  bldstat_xxx is manipulating state files under $aok_content_etc on
#  the dest FS, indicating things like if this is chrooted and so on
#
bldstat_set() {
    # msg_3 "build_staus_set($1)"
    [ -z "$1" ] && error_msg "bldstat_set() no param"
    mkdir -p "$build_status"
    touch "$build_status/$1"
}

bldstat_get() {
    # msg_3 "build_staus_get($1)"
    [ -z "$1" ] && error_msg "bldstat_get() no param"
    test -f "$build_status/$1"
    exitstatus="$?"
    case "$exitstatus" in

    0) return 0 ;;

    *) return 1 ;;

    esac
}

#  shellcheck disable=SC2120
bldstat_clear() {
    # msg_3 "bldstat_clear($1)"
    if [ -n "$1" ]; then
        fname="$build_status/$1"
        rm -f "$fname"
        # msg_3 "Cleared $fname"
        unset fname
    fi
    if [ "$(find "$build_status"/ 2>/dev/null | wc -l)" -le 1 ]; then
        rm "$build_status" -rf
        msg_3 "Cleared entire $build_status"
    fi
}

#  shellcheck disable=SC2120
select_profile() {
    replacement_profile="$1"
    if [ -z "$replacement_profile" ]; then
        error_msg "select_profile() - no param"
    fi
    msg_3 "Selecting profile: $replacement_profile"
    cp -a "$replacement_profile" "$build_root_d"/etc/profile
    #
    #  Normaly profile is sourced, but in order to be able to directly
    #  run it if manually triggering a deploy, make it executable
    #
    chmod 744 "$build_root_d"/etc/profile
    chown root: "$build_root_d"/etc/profile
    unset replacement_profile
}

create_fs() {
    # msg_2 "create_fs()"
    tarball="$1"
    [ -z "$tarball" ] && error_msg "cache_fs_image() no taball supplied"
    fs_location="${2:-$build_root_d}"
    verb="${3:-false}"
    if $verb; then # verbose mode
        verb="v"
    else
        verb=""
    fi
    [ -z "$fs_location" ] && error_msg "no fs_location detected"
    mkdir -p "$fs_location"
    cd "$fs_location" || exit 1
    msg_2 "Extracting $tarball"
    if test "${tarball#*tgz}" != "$tarball" || test "${tarball#*tar.gz}" != "$tarball"; then
        filter="z"
    else
        msg_3 "detected bzip2 format"
        filter="j"
    fi

    tar "xf${verb}${filter}" "$tarball" || {
        echo "ERROR: Failed to untar image"
        echo
        echo "Try to remove the cached file and run this again"
        echo "$src_img_cache_d/$src_tarball"
        exit 1
    }
    unset tarball
    unset fs_location
    unset verb
    unset filter
    # msg_3 "create_fs() done"
}

iCloud_mount_prompt_notification() {
    # abort if not running on iSH
    ! test -d /proc/ish && return

    echo "
 | There is one more prompt            |
 | about mounting /iCloud,             |
 | right after the package update.     |
 | After that, the rest of the install |
 | runs without need for interactions. |
"
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
        text="Do you want to mount iCloud now?"
        whiptail \
            --topleft \
            --title "Mount iCloud" \
            --yesno "$text" 0 0

        exitstatus=$?

        if [ "$exitstatus" -eq 0 ]; then
            mount -t ios x /iCloud
        fi
        unset text
        unset exitstatus
    fi
    # msg_3 "should_icloud_be_mounted()  done"
}

start_setup() {
    distro_name="$1"
    [ -z "$distro_name" ] && error_msg "start_setup() no distro_name provided"
    vers_info="$2"
    [ -z "$vers_info" ] && error_msg "start_setup() no vers_info provided"

    test -f "$additional_tasks_script" && notification_additional_tasks

    ! is_iCloud_mounted && iCloud_mount_prompt_notification

    msg_1 "Setting up iSH-AOK FS: $AOK_VERSION for ${distro_name}: $vers_info"

    if [ "$QUICK_DEPLOY" -ne 0 ]; then
        echo
        echo "***  QUICK_DEPLOY=$QUICK_DEPLOY   ***"
    fi

    if ! bldstat_get "$status_is_chrooted"; then
        msg_3 "iSH now able to run in the background"
        cat /dev/location >/dev/null &
    fi

    copy_local_bins "$distro_name"
    unset distro_name
    unset vers_info
}

copy_local_bins() {
    src_dir="$1"
    if [ -z "$src_dir" ]; then
        error_msg "call to copy_local_bins() without param!"
    fi

    msg_1 "Copying /usr/local stuff for $src_dir"

    msg_3 "Add $src_dir AOK-FS stuff to /usr/local/bin"
    mkdir -p /usr/local/bin
    cp "$aok_content"/"$src_dir"/usr_local_bin/* /usr/local/bin
    chmod +x /usr/local/bin/*

    msg_3 "Add $src_dir AOK-FS stuff to /usr/local/sbin"
    mkdir -p /usr/local/sbin
    cp "$aok_content"/"$src_dir"/usr_local_sbin/* /usr/local/sbin
    chmod +x /usr/local/sbin/*
    echo
    unset src_dir
}

notification_additional_tasks() {
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
    # msg_2 "run_additional_tasks_if_found()"
    if [ -x "$additional_tasks_script" ]; then
        msg_1 "Running additional setup tasks"
        echo
        "$additional_tasks_script" && rm "$additional_tasks_script"
        echo
    fi
    # msg_2 "run_additional_tasks_if_found()  done"
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
alpine_src_tb="alpine-minirootfs-${ALPINE_VERSION}-x86.tar.gz"
debian_src_tb="$(echo "$DEBIAN_SRC_IMAGE" | grep -oE '[^/]+$')"

#
#  Extract the release/branch/major version, from the requested Alpine,
#  gives something like 3.14
alpine_release="$(echo "$ALPINE_VERSION" | cut -d"." -f 1,2)"
alpine_src_image="https://dl-cdn.alpinelinux.org/alpine/v$alpine_release/releases/x86/$alpine_src_tb"

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

#  Indicator this is an env being built
status_being_built="env_beeing_built"
#
#  Select distro has been prepared, ie the prepare sterp does not to be
#  run during deploy
#
status_select_distro_prepared="select_distro_prepared"
#  This is chrooted
status_is_chrooted="is_chrooted"

#
#  Hint to /profile that this was a pre-built FS, meaning /etc/profile
#  should not wait for $FIRST_BOOT_NOT_DONE_HINT to disappear, and
#  post_boot.sh should not run (from inittab) /etc/profile will
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
if bldstat_get "$status_is_chrooted"; then
    build_root_d=""
    # msg_3 "This is chrooted"
elif test -f "$build_status_raw/$status_being_built"; then
    build_root_d=""
    # msg_3 "This is running on dest platform"
elif test -f "$build_status_raw/$status_prebuilt_fs"; then
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
#  First profiles used during boot to finalize setup
#  Lastly the final profiles, depending on Distribution
#  Using variables in order to only have to assign filenames in one place
#
profile_alpine_pre_built="$aok_content"/Alpine/etc/profile.prebuilt-FS
profile_alpine_setup_aok="$aok_content"/Alpine/etc/profile.setup_aok
profile_distro_select_prepare="$aok_content"/choose_distro/etc/profile.prepare
profile_distro_select="$aok_content"/choose_distro/etc/profile.select_distro
profile_debian_setup_aok="$aok_content"/Debian/etc/profile.setup_aok
profile_alpine="$aok_content"/Alpine/etc/profile
profile_debian="$aok_content"/Debian/etc/profile

#
#  After all packages are installed, if /bin/login was something other
#  than a soft-link to /bin/busybox, it will be renamed to this,
#  so it can be selected later.
#
login_original="/bin/login.alpine"

#
#  Alpine related build env
#

#
#  Either run this script chrooted if the host OS supports it, or run it
#  inside iSH-AOK once it has booted this FS
#
setup_alpine_fs="$aok_content"/Alpine/setup_alpine.sh
setup_alpine_final="$aok_content"/Alpine/setup_alpine_final_tasks.sh
setup_debian_scr="$aok_content"/Debian/setup_debian.sh
setup_common_aok="$aok_content"/common_AOK/setup_common_env.sh
setup_select_distro_prepare="$aok_content"/choose_distro/select_distro-prepare.sh

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
