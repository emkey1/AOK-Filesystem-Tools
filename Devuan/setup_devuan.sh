#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  setup_devuan.sh
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
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

prepare_env_etc() {
    msg_2 "prepare_env_etc()"

    msg_3 "hosts file helping apt tools"
    cp -a "${d_aok_base}/Devuan/etc/hosts" /etc

    #
    #  Most of the Debian services, mounting fs, setting up networking etc
    #  serve no purpose in iSH, since all this is either handled by iOS
    #  or done by the app before bootup
    #
    # # skipping openrc
    # msg_2 "Disabling previous openrc runlevel tasks"
    # rm /etc/runlevels/*/* -f

    msg_3 "Adding env versions & AOK Logo to /etc/update-motd.d"
    mkdir -p /etc/update-motd.d
    cp -a "${d_aok_base}/Devuan/etc/update-motd.d/*" /etc/update-motd.d

    msg_3 "prepare_env_etc() done"
}

#===============================================================
#
#   Main
#
#===============================================================

tsdev_start="$(date +%s)"

[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh

deploy_starting

if [ "$build_env" = "$be_other" ]; then
    echo
    echo "##  WARNING! this setup only works reliably on iOS/iPadOS and Linux(x86)"
    echo "##           You have been warned"
    echo
fi

msg_script_title "setup_devuan.sh  Devuan specific AOK env"

initiate_deploy Devuan "$(cat /etc/devuan_version)"
prepare_env_etc

#
#  This must run before any task doing apt actions
#
msg_2 "Installing sources.list"
cp "$d_aok_base"/Devuan/etc/apt_sources.list /etc/apt/sources.list

msg_1 "apt update"
apt update -y

msg_1 "apt upgrade"
apt upgrade -y

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
    msg_1 "Removing Devuan packages"
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
    msg_1 "Add Devuan packages"
    echo "$DEB_PKGS"
    bash -c "DEBIAN_FRONTEND=noninteractive apt install -y $DEB_PKGS"
fi

#
#  Common deploy, used both for Alpine & Debian
#
if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

# setup_login

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

duration="$(($(date +%s) - tsdev_start))"
display_time_elapsed "$duration" "Setup Devuan"

if [ -n "$is_prebuilt" ]; then
    msg_1 "Prebuild completed, exiting"
    exit 123
else
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
