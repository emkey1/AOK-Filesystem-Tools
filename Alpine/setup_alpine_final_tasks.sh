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
#  setup_alpine_final_tasks.sh
#
#  Completes the setup of Alpine.
#  On normal installs, this runs at the end of the install.
#  On pre-builds this will be run on first boot at destination device,
#  so it can be assumed this is running on deploy destination
#

#
#  Since this is run as /etc/profile during deploy, and this wait is
#  needed for /etc/profile (see Alpine/etc/profile for details)
#  we also put it here
#
sleep 2

tsaft_start="$(date +%s)"

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

msg_script_title "setup_alpine_final_tasks.sh - Final part of setup"

if bldstat_get "$status_prebuilt_fs"; then

    if [ "$QUICK_DEPLOY" -eq 0 ]; then
        user_interactions
    else
        msg_2 "QUICK_DEPLOY - skipping pre-build triggered user interactions"
    fi
fi

if [ "$QUICK_DEPLOY" -eq 0 ]; then
    if ! is_aok_kernel && [ -n "$AOK_APKS" ]; then
        msg_2 "Removing apps that depend on the iSH-AOK kernel"
        #
        #  aok dependent bins wont work on regular iSH,
        #  delete if any defined
        #
        # shellcheck disable=SC2086
        apk del $AOK_APKS
    fi
else
    msg_2 "QUICK_DEPLOY - skipping removal of AOK kernel packages"
fi

if [ -n "$INITIAL_LOGIN_MODE" ]; then
    #
    #  Now that final_tasks have run as root, the desired login method
    #  can be set.
    #
    msg_2 "Using defined login method. It will be used next time App is run"
    /usr/local/bin/aok -l "$INITIAL_LOGIN_MODE"
fi

select_profile "$aok_content"/Alpine/etc/profile

# msg_2 "Configure nav-key handling"
# /usr/local/bin/nav_keys.sh

/opt/AOK/common_AOK/aok_hostname/set_aok_hostname.sh
/opt/AOK/common_AOK/custom/custom_files.sh
replace_home_dirs

run_additional_tasks_if_found

#  Clear up build env
bldstat_clear_all

duration="$(($(date +%s) - tsaft_start))"
display_time_elapsed "$duration" "Setup Alpine - Final tasks"

msg_1 "This system has completed the last deploy steps and is ready!"
echo
cd
