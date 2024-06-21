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

setup_cron_env() {
    msg_2 "Setup Debian cron"

    msg_3 "Adding root crontab running periodic content"
    mkdir -p /var/spool/cron/crontabs
    rsync_chown /opt/AOK/common_AOK/cron/crontab-root /var/spool/cron/crontabs/root

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

[ -z "$d_aok_etc" ] && . /opt/AOK/tools/utils.sh

ensure_ish_or_chrooted

$setup_famdeb_scr || error_msg "in $setup_famdeb_scr"

msg_script_title "setup_debian.sh  Debian specific AOK env"
initiate_deploy Debian "$(cat /etc/debian_version)"

rsync_chown /opt/AOK/Debian/etc/update-motd.d /etc

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
