#!/bin/sh
#  shellcheck disable=SC2154
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  setup_alpine.sh
#
#  This modifies an Alpine Linux FS with the AOK changes
#

find_fastest_mirror() {
    msg_1 "Find fastest mirror"
    apk add alpine-conf || {
        error_msg "apk add alpine-conf failed"
    }
    setup-apkrepos -f
}

install_apks() {
    if [ -n "$CORE_APKS" ]; then
        msg_1 "Install core packages"

        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086
        apk add $CORE_APKS || {
            error_msg "apk add CORE_APKS failed"
        }
    else
        msg_1 "No CORE_APKS defined"
    fi

    #
    #  Install some custom apks, where the current repo version cant
    #  be used, so we use the last known to work on Debian version
    #  Since they are installed as a file, they are pinned, and wont
    #  be replaced by an apk upgrade
    #
    msg_2 "Custom apks"
    if wget https://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86/mtr-0.92-r0.apk >/dev/null 2>&1; then
        msg_3 "mtr - a full screen traceroute"
        #  shellcheck disable=SC2015
        apk add ./mtr-0.92-r0.apk && rm mtr-0.92-r0.apk || {
            error_msg "apk add mtr failed"
        }
    fi
}

prepare_env_etc() {
    msg_2 "prepare_env_etc() - Replacing a few /etc files"

    msg_3 "AOK inittab"
    cp "$aok_content"/Alpine/etc/inittab /etc

    msg_3 "iOS interfaces file"
    cp "$aok_content"/Alpine/etc/interfaces /etc/network

    if [ -f /etc/init.d/devfs ]; then
        msg_3 "Linking /etc/init.d/devfs <- /etc/init.d/dev"
        ln /etc/init.d/devfs /etc/init.d/dev
    fi

    #
    #  If edge/testing isnt added to the repositoris, testing apks can
    #  still be installed. Using mdcat as an example:
    #  apk add mdcat --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
    #
    testing_repo="https://dl-cdn.alpinelinux.org/alpine/edge/testing"
    if [ "$alpine_release" = "edge" ]; then
        msg_2 "Adding apk repository - testing"
        #    cp "$aok_content"/Alpine/etc/repositories-edge /etc/apk/repositories
        echo "$testing_repo" >>/etc/apk/repositories
    elif min_release 3.17; then
        #
        #  Only works for fairly recent releases, otherwise dependencies won't
        #  work.
        #
        msg_2 "Adding apk repository - @testing"
        msg_3 "  edge/testing is setup as a restricted repo, in order"
        msg_3 "  to install testing apks do apk add foo@testing"
        msg_3 "  In case of incompatible dependencies an error will"
        msg_3 "  be displayed, and nothing bad will happen."
        echo "@testing $testing_repo" >>/etc/apk/repositories
    fi
    # msg_3 "replace_key_etc_files() done"
}

setup_login() {
    #
    #  What login method will be used is setup during FIRST_BOOT,
    #  at this point we just ensure everything is available and initial boot
    #  will use the default login that should work on all platforms.
    #
    msg_2 "Install Alpine login methods"
    cp "$aok_content"/Alpine/bin/login.loop /bin
    chmod +x /bin/login.loop
    cp "$aok_content"/Alpine/bin/login.once /bin
    chmod +x /bin/login.once

    mv /bin/login /bin/login.original
    ln -sf /bin/login.original /bin/login

    #
    #  In order to ensure 1st boot will be able to run, for now
    #  disable login. If INITIAL_LOGIN_MODE was set, the selected
    #  method will be activated at the end of the setup
    #
    /usr/local/bin/aok -l disable >/dev/null || {
        error_msg "Failed to disable login during deploy"
    }

    if [ ! -L /bin/login ]; then
        ls -l /bin/login
        error_msg "At this point /bin/login should be a softlink!"
    fi
}

setup_cron_env() {
    msg_2 "Setup Alpine dcron"

    msg_3 "Adding root crontab running periodic content"
    mkdir -p /etc/crontabs
    cp -a "$aok_content"/common_AOK/cron/crontab-root /etc/crontabs/root

    #  shellcheck disable=SC2154
    if [ "$USE_CRON_SERVICE" = "Y" ]; then
        msg_3 "Activating dcron service, but not starting it now"
        [ "$(command -v crond)" != /usr/sbin/crond ] && error_msg "cron service requested, dcron does not seem to be installed"
        rc-update add dcron default
    else
        msg_3 "Inactivating cron service"
        #  Action only needs to be taken if it was active
        find /etc/runlevels/ | grep -q dcron && rc-update del dcron default
    fi
    # msg_3 "setup_cron_env() - done"
}

#===============================================================
#
#   Main
#
#===============================================================

tsa_start="$(date +%s)"

#
#  Ensure important devices are present.
#  this is not yet in inittab, so run it from here on 1st boot
#
echo "-->  Running fix_dev  <--"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev ignore_init_check
echo

. /opt/AOK/tools/utils.sh

if [ -n "$LOG_FILE" ]; then
    debug_sleep "Since log file is defined, will pause before starting" 2
fi

deploy_starting

#
#  Switches over into edge, so skip for now
#
#find_fastest_mirror

msg_script_title "setup_alpine.sh - Setup Alpine"

initiate_deploy Alpine "$ALPINE_VERSION"

if [ -z "$ALPINE_VERSION" ]; then
    error_msg "ALPINE_VERSION param not supplied"
fi

if ! min_release "3.16"; then
    if [ -z "${CORE_APKS##*shadow-login*}" ]; then
        # This package was introduced starting with Alpine 3.16
        msg_3 "Excluding not yet available apk 'shadow-login"
        CORE_APKS="$(echo "$CORE_APKS" | sed 's/shadow-login//')"
    fi
fi

prepare_env_etc

msg_1 "apk upgrade"
apk upgrade || {
    error_msg "apk upgrade failed"
}

install_apks

msg_2 "adding group sudo"
# apk add shadow
groupadd sudo

if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

setup_login

msg_2 "Copy /etc/motd_template"
cp -a "$aok_content"/Alpine/etc/motd_template /etc

msg_2 "Copy iSH compatible pam base-session"
cp -a "$aok_content"/Alpine/etc/pam.d/base-session /etc/pam.d

#
#  Extra sanity check, only continue if there is a runable /bin/login
#
if [ ! -x "$(readlink -f /bin/login)" ]; then
    error_msg "CRITICAL!! no run-able /bin/login present!"
fi

msg_2 "Preparing initial motd"
/usr/local/sbin/update_motd

setup_cron_env

#
#  Depending on if prebuilt or not, either setup final tasks to run
#  on first boot or now.
#
if deploy_state_is_it "$deploy_state_pre_build"; then
    set_new_etc_profile "$setup_final"
    is_prebuilt=1 # shorthand to avoid doing the above check again
else
    "$setup_final"
fi

msg_1 "Setup complete!"

duration="$(($(date +%s) - tsa_start))"
display_time_elapsed "$duration" "Setup Alpine"

if [ -n "$is_prebuilt" ]; then
    msg_1 "Prebuild completed, exiting"
    exit 123
else
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
