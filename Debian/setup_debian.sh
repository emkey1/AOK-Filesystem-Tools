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

    msg_3 "Adding root crontab running periodic content"
    mkdir -p /var/spool/cron/crontabs
    cp -a "$aok_content"/common_AOK/cron/crontab-root /var/spool/cron/crontabs/root

    #  shellcheck disable=SC2154
    if [ "$USE_CRON_SERVICE" = "Y" ]; then
        msg_3 "Activating cron service"
        # [ -z "$(command -v cron)" ] && error_msg "cron service requested, cron does not seem to be installed"
        rc-update add cron default
    else
        msg_3 "Inactivating cron service"
        #  Action only needs to be taken if it was active
        find /etc/runlevels | grep -q cron && rc-update del cron default
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

    setup_cron_env
}

#===============================================================
#
#   Main
#
#===============================================================

tsd_start="$(date +%s)"

. /opt/AOK/tools/utils.sh

#
#  Skip if chrooted
#
if this_is_ish && ! this_fs_is_chrooted; then
    msg_2 "Waiting for runlevel default to be ready, normally < 10s"
    while ! rc-status -r | grep -q default; do
        msg_3 "not ready"
        sleep 2
    done
fi

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

msg_1 "apt upgrade"
apt upgrade -y  || {
    error_msg "apt upgrade failed"
}

#
#  To ensure that
#  a) Deleting stuff, doesnt unintentionally delete what was supposed to
#     be added in DEPB_PKGS
#  b) If this is not prebuilt, and man-db is removed, saves the delay
#     if DEB_PKGS adds something with a man page, just to then delete
#     the man DB
#
#  It makes sense do first delete, then add
#
if [ -n "$DEB_PKGS_SKIP" ]; then
    msg_1 "Removing Debian packages"
    echo "$DEB_PKGS_SKIP"
    echo
    #
    #  To prevent leftovers having to potentially be purged later
    #  we do purge instead of remove, purge implies a remove
    #
    #  shellcheck disable=SC2086
    apt purge -y $DEB_PKGS_SKIP || {
	error_msg "apt remove failed"
    }

fi

if [ -n "$DEB_PKGS" ]; then
    msg_1 "Add Debian packages"
    echo "$DEB_PKGS"
    echo
    #  shellcheck disable=SC2086
    apt install -y $DEB_PKGS || {
	error_msg "apt install failed"
    }
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

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Debian"

if [ -n "$is_prebuilt" ]; then
    msg_1 "Prebuild completed, exiting"
    exit
fi
