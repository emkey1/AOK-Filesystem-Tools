#!/bin/sh
# this is sourced, shebang just to hint editors since no extension
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  setup_devuan_final_tasks.sh
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

#  Ensure important devices are present
echo "-> Running fix_dev <-"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

tsdvft_start="$(date +%s)"

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

msg_script_title "setup_devuan_final_tasks.sh - Final part of setup"

if bldstat_get "$status_prebuilt_fs"; then
    if [ "$QUICK_DEPLOY" -eq 0 ]; then
        user_interactions
    else
        msg_2 "QUICK_DEPLOY - skipping pre-build triggered user interactions"
    fi
fi

# SKIP_LOGIN
if [ -n "$INITIAL_LOGIN_MODE" ]; then
    #
    #  Now that final_tasks have run as root, the desired login method
    #  can be set.
    #
    msg_2 "Using defined login method. It will be used next time App is run"
    /usr/local/bin/aok -l "$INITIAL_LOGIN_MODE"
fi

select_profile "$aok_content"/Devuan/etc/profile

/opt/AOK/common_AOK/custom/custom_files.sh

/opt/AOK/common_AOK/aok_hostname/set_aok_hostname.sh

/usr/local/sbin/ensure_hostname_in_host_file.sh

replace_home_dirs

run_additional_tasks_if_found

#  Clear up build env
bldstat_clear_all

duration="$(($(date +%s) - tsdvft_start))"
display_time_elapsed "$duration" "Setup Devuan - Final tasks"

msg_1 "This system has completed the last deploy steps and is ready!"
echo
cd || error_msg "Failed to cd home"
