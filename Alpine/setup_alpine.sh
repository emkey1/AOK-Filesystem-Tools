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

find_fastest_mirror() {
    msg_1 "Find fastest mirror"
    apk add alpine-conf
    setup-apkrepos -f
}

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

    if [ "$QUICK_DEPLOY" -eq 0 ]; then
        msg_3 "Adding apk repository - testing"
        if [ "$ALPINE_VERSION" = "edge" ]; then
            cp "$aok_content"/Alpine/etc/repositories-edge /etc/apk/repositories
        elif min_release 3.18; then
            #
            #  Only works for fairly recent releases, otherwise dependencies won't
            #  work.
            #
            msg_3 "  edge/testing is setup as a restricted repo, in order"
            msg_3 "  to install testing apks do apk add foo@testing"
            msg_3 "  In case of incompatible dependencies an error will"
            msg_3 "  be displayed, and nothing bad will happen."
            echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories
        fi
    else
        msg_2 "QUICK_DEPLOY - not adding testing repository"
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

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

if [ -n "$DEBUG_BUILD" ]; then
    msg_2 ">>> some debug statuses"
    msg_3 "Deploy state: $(deploy_state_get)"
    if this_fs_is_chrooted; then
        msg_3 "This is chrooted"
    else
        msg_3 "NOT chrooted!"
    fi
    msg_3 "build_root_d [$build_root_d]"
    msg_3 "Detected: [$(destfs_detect)]"
    msg_2 ">>>  Debug, dropping into ash"
    /bin/ash
    error_msg "aborting buil after ash" 1
fi

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

if [ -z "$alpine_release" ]; then
    error_msg "alpine_release param not supplied"
fi

if ! min_release "3.16"; then
    if [ -z "${CORE_APKS##*shadow-login*}" ]; then
        # This package was introduced starting with Alpine 3.16
        msg_3 "Excluding not yet available apk 'shadow-login"
        CORE_APKS="$(echo "$CORE_APKS" | sed 's/shadow-login//')"
    fi
fi

prepare_env_etc

msg_1 "apk update"
apk update

msg_1 "apk upgrade"
apk upgrade

install_apks

if [ "$QUICK_DEPLOY" -eq 0 ]; then
    msg_2 "adding group sudo"
    # apk add shadow
    groupadd sudo
else
    msg_3 "QUICK_DEPLOY - skipping group sudo"
fi

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

# if ! "$setup_common_aok"; then
#     error_msg "$setup_common_aok reported error"
# fi
#
#  Setup Initial login mode will be done by setup_alpine_final_tasks.sh
#  If we do it now, final_tasks might not run as root
#

msg_2 "Preparing initial motd"
/usr/local/sbin/update_motd

if deploy_state_is_it "$deploy_state_pre_build"; then
    set_new_etc_profile "$setup_final"
else
    "$setup_final"
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
