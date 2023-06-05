#!/bin/sh
# this is sourced, shebang just to hint editors since no extension
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  setup_debian_final_tasks.sh
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Completes the setup of Debian.
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

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

msg_script_title "setup_debian_final_tasks.sh - Final part of setup"

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

select_profile "$aok_content"/Debian/etc/profile

# msg_2 "Configure nav-key handling"
# /usr/local/bin/nav_keys.sh

/opt/AOK/common_AOK/aok_hostname/set_aok_hostname.sh

replace_home_dirs
"$aok_content"/custom/custom_files.sh

run_additional_tasks_if_found

#  Clear up build env
bldstat_clear_all

msg_1 "This system has completed the last deploy steps and is ready!"
echo
cd
