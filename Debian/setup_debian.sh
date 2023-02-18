#!/bin/sh
#  shellcheck disable=SC2154

#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  This modifies a Debian Linux FS with the AOK changes
#

#
#  Since this is run as /etc/profile during deploy, and this wait is
#  needed for /etc/profile (see Alpine/etc/profile for details)
#  we also put it here
#
sleep 2

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

#  shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

install_sshd() {
    #
    #  Install sshd, then remove the service, in order to not leave it running
    #  unless requested to: with enable_sshd / disable_sshd
    #
    msg_1 "Installing openssh-server"

    msg_3 "Remove previous ssh host keys if present in FS to ensure not using known keys"
    rm /etc/ssh/ssh_host*key*

    openrc_might_trigger_errors

    apt install -y openssh-server

    msg_3 "Disable sshd for now, enable it with: enable_sshd"
    rc-update del ssh default
}

#===============================================================
#
#   Main
#
#===============================================================

if [ "$build_env" -eq 0 ]; then
    echo
    echo "##  WARNING! this setup only works reliably on iOS/iPadOS and Linux(x86)"
    echo "##           You have been warned"
    echo
fi

tsd_start="$(date +%s)"

msg_script_title "setup_debian.sh  Debian specific AOK env"

#  Ensure important devices are present
msg_2 "Running fix_dev"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev

start_setup Debian "$(cat /etc/debian_version)"

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

msg_2 "Installing custom inittab"
cp -a "$aok_content"/Debian/etc/inittab /etc

#
#  Most of the Debian services, mounting fs, setting up networking etc
#  serve no purpose in iSH, since all this is either handled by iOS
#  or done by the app before bootup
#
msg_2 "Disabling previous openrc runlevel tasks"
rm /etc/runlevels/*/* -f

msg_2 "Adding env versions & AOK Logo to /etc/update-motd.d"
mkdir -p /etc/update-motd.d
cp -a "$aok_content"/Debian/etc/update-motd.d/* /etc/update-motd.d

#
#  This must run before any task doing apt actions
#
if [ "$QUICK_DEPLOY" -eq 0 ] || [ "$QUICK_DEPLOY" -eq 2 ]; then
    msg_2 "Installing sources.list"
    cp "$aok_content"/Debian/etc/apt_sources.list /etc/apt/sources.list

    msg_2 "apt update"
    apt update -y
else
    msg_2 "QUICK_DEPLOY - skipping apt update"
fi

#
#  Do this check after update and before upgrade, to allow for it to
#  happen as early as possible, since it might require operator interaction.
#  After this the setup can run on its own.
#
! is_iCloud_mounted && should_icloud_be_mounted

#
#  Should be run before installing CORE_DEB_PKGS to minimize amount of
#  warnings displayed due to no locale being set
#
if [ "$QUICK_DEPLOY" -eq 0 ]; then
    msg_2 "Setup locale"
    msg_3 "locale warnings during this process can be ignored"
    apt install -y locales
else
    msg_2 "QUICK_DEPLOY - skipping locales"
fi

msg_2 "Installing dependencies for common setup"
apt install -y sudo openrc bash openssh-server
#
#  Common deploy, used both for Alpine & Debian
#
if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

#
#  Overriding common runbg with Debian specific, work in progress...
#
# msg_2 "Adding runbg service"
# cp -a "$aok_content"/Devuan/etc/init.d/runbg /etc/init.d
# ln -sf /etc/init.d/runbg /etc/rc2.d/S04runbg

#
#  This is installed by $setup_common_aok, so must come after that!
#  Ensure hostname is in /etc/hosts
#  This will be run from inittab each time this boots, so if name is
#  changed in iOS, the new name will be bound to 127.0.0.1
#  on next restart, or right away if you run this manually
#
/usr/local/sbin/ensure_hostname_in_host_file.sh

#
#  Do this after all essential steps, to hopefully still have
#  a working system if iSH crashes during apt upgrade
#  or install of CORE_DEB_PKGS and sshd
#
if [ "$QUICK_DEPLOY" -eq 0 ] || [ "$QUICK_DEPLOY" -eq 2 ]; then
    openrc_might_trigger_errors
    msg_1 "apt upgrade"
    apt upgrade -y

    if [ -n "$CORE_DEB_PKGS" ]; then
        msg_1 "Add core Debian packages"
        echo "$CORE_DEB_PKGS"
        bash -c "DEBIAN_FRONTEND=noninteractive apt install -y $CORE_DEB_PKGS"
    fi
    install_sshd
else
    msg_1 "QUICK_DEPLOY - skipping apt upgrade and CORE_DEB_PKGS"
fi

msg_2 "Add boot init.d items suitable for iSH"
rc-update add urandom boot

msg_2 "Add shutdown init.d items suitable for iSH"
rc-update add sendsigs off
rc-update add umountroot off
rc-update add urandom off

if [ "$QUICK_DEPLOY" -eq 0 ]; then
    msg_2 "Disable some auto-enabled services that wont make sense in iSH"
    openrc_might_trigger_errors

    rc-update del dbus default
    rc-update del elogind default
    rc-update del rsync default
    rc-update del sudo default
else
    msg_2 "QUICK_DEPLOY - did not remove default services"
fi

if bldstat_get "$status_prebuilt_fs"; then
    msg_2 "Clear apt cache on pre-built FS, saves some 50MB in the tarball"
    rm /var/cache/apt /var/lib/apt -rf

    select_profile "$setup_debian_final"
else
    "$setup_debian_final"
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
