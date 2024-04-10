#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  setup_devuan.sh
#
#  This modifies a Devuan Linux FS with the AOK changes
#

install_sshd() {
    #
    #  Install sshd, then remove the service, in order to not leave it running
    #  unless requested to: with enable-sshd / disable_sshd
    #
    msg_1 "Installing openssh-server"

    msg_2 "Remove previous ssh host keys if present in FS to ensure not using known keys"
    rm -f /etc/ssh/ssh_host*key*

    openrc_might_trigger_errors

    msg_3 "Install sshd and sftp-server (scp server part)"
    apt install -y openssh-server openssh-sftp-server

    msg_3 "Disable sshd for now, enable it with: enable-sshd"
    rc-update del ssh default
}

devuan_services() {
    #
    #  Setting up suitable services, and removing those not meaningfull
    #  on iSH
    #
    msg_2 "devuan_services()"
    msg_3 "Remove previous ssh host keys if present"
    rm -f /etc/ssh/ssh_host*key*

    # setup_cron_env
}

#===============================================================
#
#   Main
#
#===============================================================

tsd_start="$(date +%s)"

[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh

ensure_ish_or_chrooted

$setup_famdeb_scr || error_msg "in $setup_famdeb_scr"

initiate_deploy Devuan "$(cat /etc/devuan_version)"

msg_script_title "setup_devuan.sh  Devuan specific AOK env"
initiate_deploy Devuan "$(cat /etc/devuan_version)"

rsync_chown "$d_aok_base"/Devuan/etc/update-motd.d /etc

install_sshd
# setup_login
devuan_services

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
display_time_elapsed "$duration" "Setup Devuan"
echo
echo "=_=_="
echo "=====   setup_devuan completed $(date)   ====="
echo "=_=_="
echo

if [ -n "$is_prebuilt" ]; then
    msg_1 "Prebuild completed, exiting"
    exit 123
else
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
