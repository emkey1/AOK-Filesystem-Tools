#!/bin/sh
#  shellcheck disable=SC2154

#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  This modifies a Devuan Linux FS with the AOK changes
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

    # # skipping openrc
    # openrc_might_trigger_errors

    # apt install -y openssh-server

    # msg_3 "Disable sshd for now, enable it with: enable_sshd"
    # rc-update del ssh default
}

replace_key_files() {
    msg_2 "replace_key_files()"

    msg_2 "Installing custom inittab"
    cp -a "$aok_content"/Devuan/etc/inittab /etc

    msg_3 "hosts file helping apt tools"
    cp -a "$aok_content"/Devuan/etc/hosts /etc
    msg_3 "replace_key_files() done"
}

#===============================================================
#
#   Main
#
#===============================================================

tsd_start="$(date +%s)"

msg_script_title "setup_devuan.sh  Devuan specific AOK env"

#  Ensure important devices are present
msg_2 "Running fix_dev"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev

start_setup Devuan "$(cat /etc/debian_version)"

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

replace_key_files

#
#  Most of the Debian services, mounting fs, setting up networking etc
#  serve no purpose in iSH, since all this is either handled by iOS
#  or done by the app before bootup
#
# # skipping openrc
# msg_2 "Disabling previous openrc runlevel tasks"
# rm /etc/runlevels/*/* -f

msg_2 "Adding env versions & AOK Logo to /etc/update-motd.d"
mkdir -p /etc/update-motd.d
cp -a "$aok_content"/Devuan/etc/update-motd.d/* /etc/update-motd.d

#
#  This must run before any task doing apt actions
#
if [ "$QUICK_DEPLOY" -eq 0 ]; then
    msg_2 "Installing sources.list"
    cp "$aok_content"/Devuan/etc/apt_sources.list /etc/apt/sources.list

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
#  Common deploy, used both for Alpine & Debian
#
if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

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
if [ "$QUICK_DEPLOY" -eq 0 ]; then
    msg_1 "apt upgrade"
    apt upgrade -y

    # if [ -n "$CORE_DEB_PKGS" ]; then
    #     msg_1 "Add core Devuan packages"
    #     echo "$CORE_DEB_PKGS"
    #     bash -c "DEBIAN_FRONTEND=noninteractive apt install -y $CORE_DEB_PKGS"
    # fi
    # install_sshd
else
    msg_1 "QUICK_DEPLOY - skipping apt upgrade and sshd"
fi

# msg_2 "Add boot init.d items suitable for iSH"
# rc-update add urandom boot

# msg_2 "Add shutdown init.d items suitable for iSH"
# rc-update add sendsigs off
# rc-update add umountroot off
# rc-update add urandom off

# # skipping openrc
# if [ "$QUICK_DEPLOY" -eq 0 ]; then
#     msg_2 "Disable some auto-enabled services that wont make sense in iSH"
#     openrc_might_trigger_errors

#     rc-update del dbus default
#     rc-update del elogind default
#     rc-update del rsync default
#     rc-update del sudo default
# else
#     msg_2 "QUICK_DEPLOY - did not remove default services"
# fi

msg_1 "Setup complete!"
echo

bldstat_clear "$status_being_built"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Devuan"
unset duration

if bldstat_get "$status_prebuilt_fs"; then
    msg_2 "Clear apt cache on pre-built FS, saves some 50MB on the tarball"
    rm /var/cache/apt /var/lib/apt -rf
fi

#  Clear up build env
bldstat_clear_all

select_profile "$aok_content"/Devuan/etc/profile

run_additional_tasks_if_found

msg_1 "This system has completed the last deploy steps and is ready"
msg_2 "Please reboot/restart the app!"
echo
