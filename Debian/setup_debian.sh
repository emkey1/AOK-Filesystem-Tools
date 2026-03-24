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

ensure_ish_or_chrooted ""

msg_script_title "setup_debian.sh  Debian specific AOK env"
initiate_deploy Debian "$(cat /etc/debian_version)"

$setup_famdeb_scr || error_msg "in $setup_famdeb_scr"

rsync_chown /opt/AOK/Debian/etc/update-motd.d /etc

# setup_login
debian_services

replace_home_dirs

additional_prebuild_tasks

display_installed_versions_if_prebuilt

msg_1 "Debian specific setup complete!"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Debian"

complete_initial_setup
