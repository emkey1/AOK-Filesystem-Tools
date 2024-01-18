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
    cp -a "$d_aok_base"/Debian/etc/update-motd.d/* /etc/update-motd.d

    msg_3 "prepare_env_etc() done"
}

setup_cron_env() {
    msg_2 "Setup Debian cron"

    msg_3 "Adding root crontab running periodic content"
    mkdir -p /var/spool/cron/crontabs
    cp -a "$d_aok_base"/common_AOK/cron/crontab-root /var/spool/cron/crontabs/root

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

[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh

deploy_starting
msg_script_title "setup_debian.sh  Debian specific AOK env"

msg_3 "Create /var/log/wtmp"
touch /var/log/wtmp

#
#  Not normally needed, unless /var/cache/apt had been cleared,
#  so in this case, better safe than sorry
#
msg_1 "apt update"
apt update -y

msg_1 "apt upgrade"
apt upgrade -y || {
    error_msg "apt upgrade failed"
}

initiate_deploy Debian "$(cat /etc/debian_version)"
prepare_env_etc

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
#  Our
#
cp -a "$d_aok_base"/Debian/etc/init.d/rc /etc/init.d

#
#  Common deploy, used both for Alpine & Debian
#
if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

#  Ensure that Debian requires login
cp -a "$d_aok_base"/Debian/etc/pam.d/common-auth /etc/pam.d

# setup_login

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

installed_versions_if_prebuilt

msg_1 "Setup complete!"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Debian"

if [ -n "$is_prebuilt" ]; then
    msg_1 "Prebuild completed, exiting"
    exit 123
else
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
