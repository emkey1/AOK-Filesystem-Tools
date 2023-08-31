#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
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
    #  unless requested to: with enable_sshd / disable_sshd
    #
    msg_1 "Installing openssh-server"

    msg_2 "Remove previous ssh host keys if present in FS to ensure not using known keys"
    rm -f /etc/ssh/ssh_host*key*

    openrc_might_trigger_errors

    msg_3 "Install sshd and sftp-server (scp server part)"
    apt install -y openssh-server openssh-sftp-server

    msg_3 "Disable sshd for now, enable it with: enable_sshd"
    rc-update del ssh default
}

prepare_env_etc() {
    msg_2 "prepare_env_etc()"

    msg_3 "Devuan AOK inittab"
    cp -a "${aok_content}/Devuan/etc/inittab" /etc

    msg_3 "hosts file helping apt tools"
    cp -a "${aok_content}/Devuan/etc/hosts" /etc

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
    cp -a "${aok_content}/Devuan/etc/update-motd.d/*" /etc/update-motd.d

    msg_3 "prepare_env_etc() done"
}

setup_login() {
    #
    #  What login method will be used is setup during FIRST_BOOT,
    #  at this point we just ensure everything is available and initial boot
    #  will use the default loging that should work on all platforms.
    #
    # SKIP_LOGIN
    msg_2 "Install Debian AOK login methods"
    cp "${aok_content}/Debian/bin/login.loop" /bin
    chmod +x /bin/login.loop
    cp "${aok_content}/Debian/bin/login.once" /bin
    chmod +x /bin/login.once

    # TODO: enabled in Debian, verify it can be ignored here
    # cp -a "$aok_content"/Debian/etc/pam.d/common-auth /etc/pam.d

    mv /bin/login /bin/login.original
    # ln -sf /bin/login.original /bin/login

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

msg_script_title "setup_devuan.sh  Devuan specific AOK env"

initiate_deploy Devuan "$(cat /etc/devuan_version)"
prepare_env_etc

#
#  This must run before any task doing apt actions
#
msg_2 "Installing sources.list"
cp "$aok_content"/Devuan/etc/apt_sources.list /etc/apt/sources.list

msg_1 "apt update"
apt update -y

msg_1 "apt upgrade"
apt upgrade -y

if [ -n "$DEB_PKGS" ]; then
    msg_1 "Add co43 Devuan packages"
    echo "$DEB_PKGS"
    bash -c "DEBIAN_FRONTEND=noninteractive apt install -y $DEB_PKGS"
fi

# install_sshd

# msg_2 "Add boot init.d items suitable for iSH"
# rc-update add urandom boot

# msg_2 "Add shutdown init.d items suitable for iSH"
# rc-update add sendsigs off
# rc-update add umountroot off
# rc-update add urandom off

# skipping openrc
#msg_2 "Disable some auto-enabled services that wont make sense in iSH"
#openrc_might_trigger_errors
#rc-update del dbus default
#rc-update del elogind default
#rc-update del rsync default
#rc-update del sudo default

#
#  Common deploy, used both for Alpine & Debian
#
if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

setup_login

if deploy_state_is_it "$deploy_state_pre_build"; then
    set_new_etc_profile "$setup_final"
else
    "$setup_final"
    not_prebuilt=1
fi

msg_1 "Setup complete!"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Devuan"

if [ "$not_prebuilt" = 1 ]; then
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
