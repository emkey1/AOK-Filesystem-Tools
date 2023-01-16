#!/bin/sh
#  shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  This modifies an Alpine Linux FS with the AOK changes
#
#  On compatible platforms, Linux (x86) and iSH this can be run chrooted
#  before compressing the file system, to deliver a ready to be used file system.
#  When the FS is prepared on other platforms,
#  this file has to be run inside iSH once the file system has been mounted.
#

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

# shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV

install_apks() {
    if [ -n "$CORE_APKS" ]; then
        msg_1 "Install core packages"

        #  busybox-extras no longer a package starting with 3.16, so delete if present
        if [ "$(awk 'BEGIN{print ('"$ALPINE_RELEASE"' > 3.15)}')" -eq 1 ]; then
            msg_3 "Removing busybox-extras from core apks, not available past 3.15"
            CORE_APKS="$(echo "$CORE_APKS" | sed 's/busybox\-extras//')"
        fi

        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086
        apk add $CORE_APKS

        #
        #  Starting with 3.16 shadow /bin/login is in its own package
        #  simplest way to handle this is to just check if such a package
        #  is present, if found install it.
        #
        if [ -n "$(apk search shadow-login)" ]; then
            msg_3 "Installing shadow-login"
            apk add shadow-login
        fi
    fi

    if [ "$BUILD_ENV" -eq 1 ] && ! is_aok_kernel; then
        msg_2 "Skipping AOK only packages on non AOK kernels"
    elif [ -n "$AOK_APKS" ]; then
        #  Only deploy on aok kernels and if any are defined
        #  This might not be deployed on a system with the AOK kernel, but we cant
        #  know at this point in time, so play it safe and install them
        msg_2 "Add packages only for AOK kernel"
        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086
        apk add $AOK_APKS
    fi
}

replace_key_files() {
    msg_2 "Replacing a few /etc files"

    # Remove extra unused vty's, make OpenRC work
    cp "$AOK_CONTENT"/Alpine/etc/inittab /etc

    # Fake interfaces file
    cp "$AOK_CONTENT"/Alpine/etc/interfaces /etc/network

    ln /etc/init.d/devfs /etc/init.d/dev

    # Networking, hostname and possibly others can't start because of
    # current limitations in iSH So we fake it out
    rm /etc/init.d/networking

    # More hackery.  Initial case is the need to make pam_motd.so optional
    # So that the ish user will work in Alpine 3.14
    cp "$AOK_CONTENT"/Alpine/etc/pam.d/* /etc/pam.d
}

#===============================================================
#
#   Main
#
#===============================================================

tsa_start="$(date +%s)"

start_setup Alpine

if [ -z "$ALPINE_RELEASE" ]; then
    error_msg "ALPINE_RELEASE param not supplied"
fi

msg_2 "Setting $FILE_ALPINE_RELEASE to $ALPINE_RELEASE"
echo "$ALPINE_RELEASE" >"$FILE_ALPINE_RELEASE"

msg_2 "apk update"
apk update

! is_iCloud_mounted && should_icloud_be_mounted

msg_2 "apk upgrade"
apk upgrade

install_apks

replace_key_files

msg_2 "adding pkg shadow & group sudo"
apk add shadow
groupadd sudo

#
#  Extra sanity check, only continue if there is a runable /bin/login
#
if [ ! -x /bin/login ]; then
    error_msg "CRITICAL!! no run-able /bin/login present!"
fi

#
#  Setup dcron if it was included in CORE_APKS
#
if [ -x dcron ]; then
    msg_2 "--  Adding service dcron  --"
    rc-update add dcron
    rc-service dcron default
    msg_3 "Setting cron for checking every 15 mins"
    cp "$AOK_CONTENT"/Alpine/cron/15min/* /etc/periodic/15min
fi

msg_1 "Running $SETUP_COMMON_AOK"
"$SETUP_COMMON_AOK"

msg_1 "running $SETUP_ALPINE_FINAL"
"$SETUP_ALPINE_FINAL"

select_profile "$PROFILE_ALPINE"

duration="$(($(date +%s) - tsa_start))"
display_time_elapsed "$duration" "Setup Alpine"

run_additional_tasks_if_found
