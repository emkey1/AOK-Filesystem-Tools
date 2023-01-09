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

#===============================================================
#
#   Main
#
#===============================================================

tsd_start="$(date +%s)"

start_setup Debian

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

#
#  Most of the Debian services, mounting fs, setting up networking etc
#  serve no purpose in iSH, since all this is either handled by iPadOS
#  or done before bootup, so we only need to run actual services.
#
msg_2 "Disabling previous runlevel tasks"
rm /etc/runlevels/sysinit/*
rm /etc/runlevels/default/*

#
#  This speeds up update / upgrade quite a bit, you can always
#  re-enable later if it is wished for
#
msg_2 "Installing sources.list without deb-src entries"
cp /opt/AOK/Debian/etc/apt_sources.list /etc/apt/sources.list

msg_2 "apt update"
apt update

! is_iCloud_mounted && should_icloud_be_mounted

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

msg_2 "apt upgrade"
apt upgrade -y

#
#  Ensure hostname is in /etc/hosts
#  If not there will be various error messages displayed.
#  This will be run each time this boots, so if name is changed
#  the new name will be bound to 127.0.0.1
#
/usr/local/sbin/ensure_hostname_in_host_file.sh

msg_2 "Installing custom inittab"
cp -av /opt/AOK/Debian/etc/inittab /etc

#
#  Install sshd, then remove the service, in order to not leave it running
#  unless requested to: with enable_sshd / disable_sshd
#
msg_1 "Installing openssh-server"
msg_3 "Remove ssh host keys if present in FS to ensure not using known keys"
rm /etc/ssh/ssh_host*key*

openrc_might_trigger_errors

apt install openssh-server

msg_3 "Disable sshd for now, enable it with: enable_sshd"
rc-update del ssh default

#
#  Common deploy, used both for Alpine & Debian
#
msg_1 "Running $SETUP_COMMON_AOK"
"$SETUP_COMMON_AOK"

msg_1 "Setup complete!"
echo

build_status_clear "$STATUS_BEING_BUILT"

select_profile "$PROFILE_DEBIAN"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Debian"
unset duration

run_additional_tasks_if_found

msg_1 "Your system is setup! Please reboot / restart app"
