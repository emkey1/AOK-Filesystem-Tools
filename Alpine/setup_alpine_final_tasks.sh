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
#  Completes the setup of Alpine
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

msg_script_title "setup_alpine_final_tasks.sh - Final part of setup"

if [ "$QUICK_DEPLOY" -eq 0 ]; then
    if ! is_aok_kernel; then
        msg_2 "Removing apps that depend on the iSH-AOK kernel"
        #
        #  aok dependent bins serve no purpose on other platforms, delete
        #
        # shellcheck disable=SC2086
        apk del $AOK_APKS
    fi
else
    msg_2 "QUICK_DEPLOY - skipping removal of AOK kernel packages"
fi

#  Clear up build env
bldstat_clear_all

select_profile "$aok_content"/Alpine/etc/profile

run_additional_tasks_if_found

msg_1 "This system has completed the last deploy steps and is ready"
msg_2 "Please reboot/restart the app!"
echo
