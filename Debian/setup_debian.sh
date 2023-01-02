#!/bin/sh
#  shellcheck disable=SC2154

#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#
#  Assumed to allways be run on destination platform
#

#  shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV

activate_runbg_debian() {

    msg_3 "Adding Debian runbg service"
    cp -a "$AOK_CONTENT"/Debian/etc/init.d/runbg /etc/init.d

    #
    #  Since this was booted up with potentially invalid settings for
    #  openrc, at this time this service can not reliably be set up with
    #  the normal procedure:
    #    rc-update add runbg
    #    rc-service runbg start
    #  Instead we need to hardcode the intended state manually.
    #  The inittab used by this deploy will reset the openrc env into
    #  a clean state during future bootups, so this service should
    #  start normally as intended on all future bootups.
    #
    msg_3 "Activating runbg"
    cd /etc/runlevels/default || exit 126
    ln -sf /etc/init.d/runbg .
}

#===============================================================
#
#   Main
#
#===============================================================

tsd_start="$(date +%s)"

test -f "$ADDITIONAL_TASKS_SCRIPT" && notification_additional_tasks

! is_iCloud_mounted && iCloud_mount_prompt_notification

msg_1 "Setup Debian"

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

#
#  This speeds up update / upgrade quite a bit, you can always
#  re-enable later if it is wished for
#
msg_2 "sources.list without deb-src entries"
cp /opt/AOK/Debian/etc/apt_sources.list /etc/apt/sources.list

msg_2 "apt update & upgrade"
apt update && apt upgrade -y

! is_iCloud_mounted && should_icloud_be_mounted

msg_2 "Add our Debian stuff to /usr/local/bin"
mkdir -p /usr/local/bin
cp "$AOK_CONTENT"/Debian/usr_local_bin/* /usr/local/bin
chmod +x /usr/local/bin/*

msg_2 "Add our Debian stuff to /usr/local/sbin"
mkdir -p /usr/local/sbin
cp "$AOK_CONTENT"/Debian/usr_local_sbin/* /usr/local/sbin
chmod +x /usr/local/sbin/*

# Ensure hostname is in /etc/hosts
/usr/local/sbin/ensure_hostname_in_host_file.sh

msg_2 "Installing custom inittab"
cp -av /opt/AOK/Debian/etc/inittab /etc

msg_3 "Remove ssh host keys if present in FS to ensure not using known keys"
rm /etc/ssh/ssh_host*key*

msg_2 "Installing openssh-server"
apt install openssh-server

#
#  Most of the Debian services, mounting fs, setting up networking etc
#  serve no purpose in iSH, since all this is either handled by iPadOS
#  or done before bootup, so we only need to run actual services
#
msg_3 "Disabling previous runlevel tasks"
rm /etc/runlevels/sysinit/*
rm /etc/runlevels/default/*

#
#  Since iSH doesn't do any cleanup upon shutdown, services will leave
#  their previous running state in /run, confusing Debian on next boot.
#  So far, the simplest way to avoid this is to replace /run early on
#  bootup with a state of no services running, allowing all intended
#  services to start in a fresh state.
#  inittab runs /usr/local/sbin/reset-run-dir.sh before switching to
#  runlevel default during bootup, using this tarball to reset /run
#
msg_3 "Copying bootup run state to /etc/opt/openrc_empty_run.tgz"
cp "$AOK_CONTENT"/Debian/openrc_empty_run.tgz /etc/opt

activate_runbg_debian

msg_1 "Running $SETUP_COMMON_AOK"
"$SETUP_COMMON_AOK"

build_status_clear "$STATUS_BEING_BUILT"

select_profile "$PROFILE_DEBIAN"

run_additional_tasks_if_found

msg_1 "Your system is setup! Please reboot / restart app"

duration="$(($(date +%s) - tsd_start))"
printf "\nTime elapsed for deploy: %ss\n" "$duration"
