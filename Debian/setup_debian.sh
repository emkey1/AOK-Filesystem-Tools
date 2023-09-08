#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  setup_debian.sh
#
#  This modifies a Debian Linux FS with the AOK changes
#

prepare_env_etc() {
    msg_2 "prepare_env_etc() - Replacing a few /etc files"

    msg_3 "Debian AOK inittab"
    cp -a "$aok_content"/Debian/etc/inittab /etc

    #
    #  Most of the Debian services, mounting fs, setting up networking etc
    #  serve no purpose in iSH, since all this is either handled by iOS
    #  or done by the app before bootup
    #
    msg_3 "Disabling previous openrc runlevel tasks"
    rm /etc/runlevels/*/* -f

    msg_3 "Adding env versions & AOK Logo to /etc/update-motd.d"
    mkdir -p /etc/update-motd.d
    cp -a "$aok_content"/Debian/etc/update-motd.d/* /etc/update-motd.d

    msg_3 "prepare_env_etc() done"
}

setup_cron_env() {
    msg_2 "Setup Debian cron"

    msg_3 "root crontab running periodic content"
    mkdir -p /var/spool/cron/crontabs
    cp -a "$aok_content"/common_AOK/cron/crontab-root /var/spool/cron/crontabs/root

    #  shellcheck disable=SC2154
    if [ "$USE_CRON_SERVICE" = "Y" ]; then
	msg_3 "Activating cron service"
	[ "$(command -v cron)" != /usr/sbin/cron ] && error_msg "cron service requested, cron does not seem to be installed"
	rc-update add cron default
    else
	msg_3 "Inactivating cron service"
	rc-update del cron default
    fi
    # msg_3 "setup_cron_env() - done"
}

setup_login() {
    #
    #  What login method will be used is setup during FIRST_BOOT,
    #  at this point we just ensure everything is available and initial boot
    #  will use the default loging that should work on all platforms.
    #
    # SKIP_LOGIN
    msg_2 "Install Debian AOK login methods"
    cp "$aok_content"/Debian/bin/login.loop /bin
    chmod +x /bin/login.loop
    cp "$aok_content"/Debian/bin/login.once /bin
    chmod +x /bin/login.once

    #  Ensure that Debian requires login
    cp -a "$aok_content"/Debian/etc/pam.d/common-auth /etc/pam.d

    mv /bin/login /bin/login.original

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

debian_services() {
    #
    #  Setting up suitable services, and removing those not meaningfull
    #  on iSH
    #
    msg_2 "debian_services()"
    msg_3 "Remove previous ssh host keys if present"
    rm -f /etc/ssh/ssh_host*key*

    # msg_2 "Add services for runlevel boot"
    # rc-update add urandom boot

    #msg_3 "Add services for runlevel off"
    #rc-update add sendsigs off
    #rc-update add urandom off

    #msg_3 "Disable some auto-enabled services that wont make sense in iSH"
    #openrc_might_trigger_errors

    #rc-update del dbus default
    #rc-update del elogind default
    #rc-update del rsync default
    #rc-update del sudo default

    setup_cron_env
}

#===============================================================
#
#   Main
#
#===============================================================

tsd_start="$(date +%s)"

#
#  Ensure important devices are present.
#  this is not yet in inittab, so run it from here on 1st boot
#
echo "-->  Running fix_dev  <--"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev ignore_init_check
echo

. /opt/AOK/tools/utils.sh

deploy_starting

if [ "$build_env" = "$be_other" ]; then
    echo
    echo "##  WARNING! this setup only works reliably on iOS/iPadOS and Linux(x86)"
    echo "##           You have been warned"
    echo
fi

msg_script_title "setup_debian.sh  Debian specific AOK env"

msg_3 "Create /var/log/wtmp"
touch /var/log/wtmp

initiate_deploy Debian "$(cat /etc/debian_version)"

prepare_env_etc

# msg_1 "apt update"
# apt update -y

msg_1 "apt upgrade"
apt upgrade -y

if [ -n "$DEB_PKGS_SKIP" ]; then
    msg_1 "Removing Debian packages"
    echo "$DEB_PKGS_SKIP"
    echo
    #
    #  To prevent leftovers having to potentially be purged later
    #  we do purge instead of remove, purge implies a remove
    #
    #  shellcheck disable=SC2086
    apt purge -y $DEB_PKGS_SKIP
fi
echo

if [ -n "$DEB_PKGS" ]; then
    msg_1 "Add Debian packages"
    echo "$DEB_PKGS"
    #  shellcheck disable=SC2086
    apt install -y $DEB_PKGS
fi
echo

#
#  Common deploy, used both for Alpine & Debian
#
if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

setup_login

debian_services

#
#  Overriding common runbg with Debian specific, work in progress...
#
# msg_2 "Adding runbg service"
# cp -a "$aok_content"/Devuan/etc/init.d/runbg /etc/init.d
# ln -sf /etc/init.d/runbg /etc/rc2.d/S04runbg

#
#  Depending on if prebuilt or not, either setup final tasks to run
#  on first boot or now.
#
if deploy_state_is_it "$deploy_state_pre_build"; then
    set_new_etc_profile "$setup_final"
else
    "$setup_final"
    not_prebuilt=1
fi

msg_1 "Setup complete!"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Debian"

if [ "$not_prebuilt" = 1 ]; then
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
