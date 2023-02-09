#!/bin/sh
#  shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  This modifies an Alpine Linux FS with the AOK changes
#

#
#  Since this is run as /etc/profile during deploy, and this wait is
#  needed for /etc/profile (see Alpine/etc/profile for details)
#  we also put it here
#
sleep 2

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

install_apks() {
    if [ -n "$CORE_APKS" ] && [ "$QUICK_DEPLOY" -ne 1 ]; then
        msg_1 "Install core packages"

        if [ "$QUICK_DEPLOY" -eq 0 ]; then
            #  busybox-extras no longer a package starting with 3.16, so delete if present
            if [ "$(awk 'BEGIN{print ('"$alpine_release"' > 3.15)}')" -eq 1 ]; then
                msg_3 "Removing busybox-extras from core apks, not available past 3.15"
                CORE_APKS="$(echo "$CORE_APKS" | sed 's/busybox\-extras//')"
            fi
        elif [ "$QUICK_DEPLOY" -eq 1 ]; then
            #
            #  If you want to override CORE_APKS in a quick deploy
            #  set it to a value higher than 1
            #
            msg_2 "QUICK_DEPLOY - doing minimal package install"
            #  probably absolute minimal without build errors
            # CORE_APKS="openssh bash openrc sudo dcron dcron-openrc"
            CORE_APKS="bash openrc"
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
    elif [ "$QUICK_DEPLOY" -eq 1 ]; then
        msg_1 "QUICK_DEPLOY - skipping CORE_APKS"
    else
        msg_1 "No CORE_APKS defined"
    fi

    if [ "$QUICK_DEPLOY" -ne 0 ]; then
        msg_2 "QUICK_DEPLOY - skipping AOK_APKS"
    elif [ "$build_env" -eq 1 ] && ! is_aok_kernel; then
        msg_2 "Skipping AOK only packages on non AOK kernels"
    elif [ -n "$AOK_APKS" ]; then
        #  Only deploy on aok kernels and if any are defined
        #  This might not be deployed on a system with the AOK kernel, but we cant
        #  know at this point in time, so play it safe and install them
        if [ "$QUICK_DEPLOY" -eq 0 ]; then
            msg_2 "Add packages only for AOK kernel"
            # In this case we want the variable to expand into its components
            # shellcheck disable=SC2086
            apk add $AOK_APKS
        else
            msg_2 "QUICK_DEPLOY - skipping AOK kernel packages"
        fi
    else
        msg_1 "No AOK_APKS defined"
    fi
}

replace_key_files() {
    msg_2 "replace_key_files()"
    msg_2 "Replacing a few /etc files"

    msg_3 "Our inittab"
    cp "$aok_content"/Alpine/etc/inittab /etc

    msg_3 "iOS interfaces file"
    cp "$aok_content"/Alpine/etc/interfaces /etc/network

    if [ -f /etc/init.d/devfs ]; then
        msg_3 "Linking /etc/init.d/devfs <- /etc/init.d/dev"
        ln /etc/init.d/devfs /etc/init.d/dev
    fi

    if [ "$QUICK_DEPLOY" -eq 0 ]; then
        if [ "$ALPINE_VERSION" = "edge" ]; then
            msg_3 "Adding apk repositories containing testing"
            cp "$aok_content"/Alpine/etc/repositories-edge /etc/apk/repositories
        elif [ "$ALPINE_VERSION" = "3.17.1" ]; then
            msg_3 "Adding edge/testing as a restricted repo"
            msg_3 " in order to install testing apks do apk add foo@testing"
            msg_3 " in case of incompatible dependencies an error will be displayed"
            msg_3 " and nothing bad will happen."
            echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories
        fi
    else
        msg_2 "QUICK_DEPLOY - not adding testing repository"
    fi

    # Networking, hostname and possibly others can't start because of
    # current limitations in iSH So we fake it out
    # rm /etc/init.d/networking

    case "$alpine_release" in

    "3.14")
        #
        #  More hackery.  Initial case is the need to make pam_motd.so
        #  optional, so that the ish user will work in Alpine 3.14
        #
        msg_3 "Replacing /etc/pam.d for 3.14"
        $cp "$aok_content"/Alpine/etc/pam.d/* /etc/pam.d
        ;;

    *) ;;

    esac
    msg_3 "replace_key_files() done"
}

#===============================================================
#
#   Main
#
#===============================================================

tsa_start="$(date +%s)"

msg_script_title "setup_alpine.sh - Setup Alpine"

#  Ensure important devices are present
msg_2 "Running fix_dev"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev

start_setup Alpine "$ALPINE_VERSION"

if [ -z "$alpine_release" ]; then
    error_msg "alpine_release param not supplied"
fi

msg_2 "Setting $file_alpine_release to $ALPINE_VERSION"
echo "$ALPINE_VERSION" >"$file_alpine_release"

replace_key_files

msg_2 "apk update"
apk update

! is_iCloud_mounted && should_icloud_be_mounted

msg_2 "apk upgrade"
apk upgrade

install_apks

msg_2 "Copy /etc/motd_template"
cp -a "$aok_content"/Alpine/etc/motd_template /etc

msg_2 "Copy iSH compatible pam base-session"
cp -a "$aok_content"/Alpine/etc/pam.d/base-session /etc/pam.d

if [ "$QUICK_DEPLOY" -eq 0 ]; then
    msg_2 "adding group sudo"
    # apk add shadow
    groupadd sudo
else
    msg_3 "QUICK_DEPLOY - skipping group sudo"
fi

#
#  Extra sanity check, only continue if there is a runable /bin/login
#
if [ ! -x /bin/login ]; then
    error_msg "CRITICAL!! no run-able /bin/login present!"
fi

#
#  Setup dcron if it was included in CORE_APKS
#
if apk info -e dcron >/dev/null; then
    msg_2 "Detected dcron, adding service"
    openrc_might_trigger_errors
    rc-update add dcron default
    rc-service dcron start
    msg_3 "Setting dcron for checking every 15 mins"
    cp "$aok_content"/Alpine/cron/15min/* /etc/periodic/15min
fi

if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

if [ "$QUICK_DEPLOY" -ne 0 ]; then
    msg_2 "QUICK_DEPLOY - disabling custom login"
    INITIAL_LOGIN_MODE="disable"
fi

#
#  Setup Initial login mode
#
msg_2 "Setting defined login mode: $INITIAL_LOGIN_MODE"
#  shellcheck disable=SC2154
/usr/local/bin/aok -l "$INITIAL_LOGIN_MODE"

msg_2 "Preparing initial motd"
/usr/local/sbin/update_motd

msg_1 "Setup complete!"
echo

duration="$(($(date +%s) - tsa_start))"
display_time_elapsed "$duration" "Setup Alpine"

#
#  This should run on destination platform
#
if is_chrooted; then
    select_profile "$setup_alpine_final"
else
    "$setup_alpine_final"
fi
