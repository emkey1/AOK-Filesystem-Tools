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

disabeling_services() {
    msg_2 "disabeling_services($1)"
    if [ -z "$1" ]; then
        error_msg "no dir param"
    fi

    ddir="/etc/$1"
    if [ ! -d "$ddir" ]; then
        error_msg "dir $ddir does not seem to exist"
    fi
    cd "$ddir" || exit 124
    mkdir -p NOT
    shift

    while [ -n "$1" ]; do
        mv "$1" NOT
        shift
    done
}


#===============================================================
#
#   Main
#
#===============================================================

test -f "$ADDITIONAL_TASKS_SCRIPT" && notification_additional_tasks

! is_iCloud_mounted && iCloud_mount_prompt_notification

msg_1 "Setup Debian"

if test -f /AOK ; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

msg_2 "Using custom inittab"
cp -av /opt/AOK/Debian/etc/inittab /etc

msg_2 "removing bad runbg if found"
rm -f /etc/init.d/runbg

#
#  This speeds up update / upgrade quite a bit, you can always
#  re-enable later if it is wished for
#
msg_2 "commenting out all deb-src entries"
cp /opt/AOK/Debian/etc/apt_sources.list /etc/apt/sources.list

#
# Trying to balance what services can br removed whilst not causing system
# to be unbootable, work in progress, so not activated yet...
#
# msg_2 "Disabeling some services"
# disabeling_services rcS.d S01mountkernfs.sh
# disabeling_services rc2.d S01rsyslog S02cron S02rsync
# disabeling_services rc3.d S01rsyslog S02cron S02rsync

msg_2 "apt update & upgrade"
apt update && apt upgrade -y

! is_iCloud_mounted && should_icloud_be_mounted

msg_2 "Installing openssh-server & net-tools (ifconfig)"
apt install openssh-server net-tools


msg_2 "Add our Debian stuff to /usr/local/bin"
mkdir -p /usr/local/bin
cp "$AOK_CONTENT"/Debian/usr_local_bin/* /usr/local/bin
chmod +x /usr/local/bin/*


msg_2 "Add our Debian stuff to /usr/local/sbin"
mkdir -p /usr/local/sbin
cp "$AOK_CONTENT"/Debian/usr_local_sbin/* /usr/local/sbin
chmod +x /usr/local/sbin/*


msg_1 "Running $SETUP_COMMON_AOK"
"$SETUP_COMMON_AOK"


build_status_clear "$STATUS_BEING_BUILT"

select_profile "$PROFILE_DEBIAN"

run_additional_tasks_if_found

msg_1 "Your system is setup! Please reboot / restart app"
