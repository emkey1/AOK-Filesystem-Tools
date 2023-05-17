#!/bin/sh
#  shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  setup_alpine.sh
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

        if [ "$QUICK_DEPLOY" -eq 1 ]; then
            #
            #  If you want to override CORE_APKS in a quick deploy
            #  set it to a value higher than 1
            #
            msg_3 "QUICK_DEPLOY=1 - doing minimal package install"
            #  probably absolute minimal without build errors
            # CORE_APKS="openssh bash openrc sudo dcron dcron-openrc"
            CORE_APKS="bash openrc"
        fi

        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086
        apk add $CORE_APKS
    elif [ "$QUICK_DEPLOY" -eq 1 ]; then
        msg_1 "QUICK_DEPLOY - skipping CORE_APKS"
    else
        msg_1 "No CORE_APKS defined"
    fi
}

install_aok_apks() {
    if [ -z "$AOK_APKS" ]; then
        msg_1 "No AOK_APKS defined"
        return
    elif [ "$QUICK_DEPLOY" -ne 0 ]; then
        msg_1 "QUICK_DEPLOY - skipping AOK_APKS"
        return
    elif ! bldstat_get "$status_prebuilt_fs" && ! is_aok_kernel; then
        msg_1 "Skipping AOK only packages on non AOK kernel"
        return
    fi

    msg_1 "Install packages only for AOK kernel"
    #
    #  This might not be deployed on a system with the AOK kernel, but we cant
    #  know at this point in time, so play it safe and install them
    #  setup_alpine_final_tasks.sh will remove them, if run on a non-AOK kernel
    #

    # In this case we want the variable to expand into its components
    # shellcheck disable=SC2086
    apk add $AOK_APKS
    echo
}

replace_key_files() {
    msg_2 "prepare_env_etc() - Replacing a few /etc files"

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
        elif [ "$alpine_release" = "3.17" ]; then
            msg_3 "Adding edge/testing as a restricted repo"
            msg_3 " in order to install testing apks do apk add foo@testing"
            msg_3 " in case of incompatible dependencies an error will be displayed"
            msg_3 " and nothing bad will happen."
            echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories
        fi
    else
        msg_2 "QUICK_DEPLOY - not adding testing repository"
    fi

    msg_3 "replace_key_files() done"
}

setup_login() {
    #
    #  What login method will be used is setup during FIRST_BOOT,
    #  at this point we just ensure everything is available and initial boot
    #  will use the default loging that should work on all platforms.
    #
    msg_2 "Install Alpine login methods"
    cp "$aok_content"/Alpine/bin/login.loop /bin
    chmod +x /bin/login.loop
    cp "$aok_content"/Alpine/bin/login.once /bin
    chmod +x /bin/login.once

    cp -av /bin/login /bin/login.original
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

msg_2 "Setting $file_alpine_release to $alpine_release"
echo "$alpine_release" >"$file_alpine_release"

if ! min_release "3.16"; then
    if [ -z "${CORE_APKS##*shadow-login*}" ]; then
        # This package was introduced starting with Alpine 3.16
        msg_3 "Excluding not yet available apk 'shadow-login"
        CORE_APKS="$(echo "$CORE_APKS" | sed 's/shadow-login//')"
    fi
fi

replace_key_files

msg_1 "apk update"
apk update

#
#  Doing some user interactions as early as possible, unless this is
#  pre-built, then this happens on first boot via setup_alpine_final_tasks.sh
#
if ! bldstat_get "$status_prebuilt_fs"; then
    user_interactions
fi

msg_1 "apk upgrade"
apk upgrade

install_apks
install_aok_apks

setup_login

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

if [ "$QUICK_DEPLOY" -ne 0 ]; then
    msg_2 "QUICK_DEPLOY - disabling custom login"
    # shellcheck disable=SC2034
    INITIAL_LOGIN_MODE="disable"
fi

# msg_2 "Installing dependencies for common setup"
# apk add sudo openrc bash openssh-server

if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi
#
#  Setup Initial login mode will be done by setup_alpine_final_tasks.sh
#  If we do it now, final_tasks might not run as root
#

msg_2 "Preparing initial motd"
/usr/local/sbin/update_motd

if bldstat_get "$status_prebuilt_fs"; then
    select_profile "$setup_alpine_final"
else
    "$setup_alpine_final"
    not_prebuilt=1
fi

msg_1 "Setup complete!"

duration="$(($(date +%s) - tsa_start))"
display_time_elapsed "$duration" "Setup Alpine"

if [ "$not_prebuilt" = 1 ]; then
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
