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
#  On compatible platforms, Linux (x86) and iSH this can be run chrooted
#  before compressing the file system, to deliver a ready to be used file system.
#  When the FS is prepared on other platforms,
#  this file has to be run inside iSH once the file system has been mounted.
#

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

#  shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV

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

tsd_start="$(date +%s)"

start_setup Debian

#
#  Ensure hostname is in /etc/hosts
#  If not there will be various error messages displayed.
#  This will be run from inittab each time this boots, so if name is
#  changed in iOS, the new name will be bound to 127.0.0.1
#  on next restart, or right away if you run this manually
#
/usr/local/sbin/ensure_hostname_in_host_file.sh

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

#
#  Since iSH doesn't do any cleanup upon shutdown, services will leave
#  their previous running state in /run, confusing Debian on next boot.
#  So far, the simplest way to avoid this is to replace /run early on
#  bootup with a state of no services running, allowing all intended
#  services to start in a fresh state.
#  inittab runs /usr/local/sbin/reset-run-dir.sh before switching to
#  runlevel default during bootup, using this tarball to reset /run
#
msg_2 "Copying bootup run state to /etc/opt/openrc_empty_run.tgz"
cp "$AOK_CONTENT"/Debian/openrc_empty_run.tgz /etc/opt

msg_2 "Installing custom inittab"
cp -a "$AOK_CONTENT"/Debian/etc/inittab /etc

#
#  Most of the Debian services, mounting fs, setting up networking etc
#  serve no purpose in iSH, since all this is either handled by iOS
#  or done by the app before bootup
#
msg_2 "Disabling previous openrc runlevel tasks"
rm /etc/runlevels/*/* -f

msg_2 "Adding env versions & AOK Logo to /etc/update-motd.d"
mkdir -p /etc/update-motd.d
cp -a "$AOK_CONTENT"/Debian/etc/update-motd.d/* /etc/update-motd.d

#
#  This must run before any task doing apt actions
#
if [ "$QUICK_DEPLOY" -ne 1 ]; then
    msg_2 "Installing sources.list"
    cp "$AOK_CONTENT"/Debian/etc/apt_sources.list /etc/apt/sources.list

    msg_2 "apt update"
    apt update
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
if [ "$QUICK_DEPLOY" -ne 1 ]; then
    msg_2 "Setup locale"
    apt install locales
fi

#
#  Common deploy, used both for Alpine & Debian
#
msg_1 "Running $SETUP_COMMON_AOK"
"$SETUP_COMMON_AOK"

#
#  Do this after all other essential configs, to hopefully still have
#  a working system if iSH crashes during apt upgrade
#  or install of CORE_DEB_PKGS
#
if [ "$QUICK_DEPLOY" -ne 1 ]; then
    msg_1 "apt upgrade"
    apt upgrade -y

    if [ -n "$CORE_DEB_PKGS" ]; then
	msg_1 "Add core Debian packages"
	echo "$CORE_DEB_PKGS"
	bash -c "DEBIAN_FRONTEND=noninteractive apt install -y $CORE_DEB_PKGS"
    fi
    install_sshd
fi

#msg_2 "Setting runlevel default"
#openrc default

msg_1 "Setup complete!"
echo

bldstat_clear "$STATUS_BEING_BUILT"

select_profile "$PROFILE_DEBIAN"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Debian"
unset duration


run_additional_tasks_if_found

msg_1 "Your system is setup! Please reboot / restart app"
