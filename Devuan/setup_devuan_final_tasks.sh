#!/bin/sh
# this is sourced, shebang just to hint editors since no extension
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Completes the setup of Debian.
#  On normal installs, this runs at the end of the install.
#  On pre-builds this will be run on first boot at destination device
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

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

msg_script_title "setup_devuan_final_tasks.sh - Final part of setup"

# If this was a pre-built FS, now is the time to ask if iCloud should be mounted
if bldstat_get "$status_prebuilt_fs"; then
    msg_3 "Considering /iCloud mount for a pre-built FS"
    ! is_iCloud_mounted && should_icloud_be_mounted

    msg_1 "Re-populating the apt-cache, cleared in order to keep FS image size down"
    apt update
fi

#  Clear up build env
bldstat_clear_all

select_profile "$aok_content"/Devuan/etc/profile

run_additional_tasks_if_found

msg_1 "This system has completed the last deploy steps and is ready"
echo
