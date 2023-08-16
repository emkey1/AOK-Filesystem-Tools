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
#  setup_final_tasks.sh
#
#  Completes the setup of Alpine or Debian.
#  On normal installs, this runs at the end of the install.
#  On pre-builds this will be run on first boot at destination device,
#  so it can be assumed this is running on deploy destination
#

install_aok_apks() {
    if ! this_is_aok_kernel; then
        msg_1 "Skipping AOK only packages on non AOK kernel"
        return
    elif [ "$QUICK_DEPLOY" -ne 0 ]; then
        msg_1 "QUICK_DEPLOY - skipping AOK_APKS"
        return
    elif [ -z "$AOK_APKS" ]; then
        msg_1 "No AOK_APKS defined"
        return
    fi

    msg_1 "Install packages only for AOK kernel"

    # In this case we want the variable to expand into its components
    # shellcheck disable=SC2086
    apk add $AOK_APKS
    echo
}

#===============================================================
#
#   Main
#
#===============================================================

tsaft_start="$(date +%s)"

. /opt/AOK/tools/utils.sh
. /opt/AOK/tools/user_interactions.sh

if [ -n "$LOG_FILE" ]; then
    debug_sleep "Since log file is defined, will pause before starting" 2
fi

deploy_state_set "$deploy_state_finalizing"

msg_script_title "setup_final_tasks.sh - Final part of setup"

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

user_interactions

destfs_is_alpine && install_aok_apks

"$aok_content"/common_AOK/aok_hostname/set_aok_hostname.sh

set_initial_login_mode

if destfs_is_alpine; then
    next_etc_profile="$aok_content/Alpine/etc/profile"
elif destfs_is_debian; then
    next_etc_profile="$aok_content/Debian/etc/profile"
elif destfs_is_devuan; then
    next_etc_profile="$aok_content/Devuan/etc/profile"
else
    error_msg "Undefined Distro, cant set next_etc_profile"
fi

set_new_etc_profile "$next_etc_profile"

"$aok_content"/common_AOK/custom/custom_files.sh

/usr/local/sbin/ensure_hostname_in_host_file.sh

replace_home_dirs

run_additional_tasks_if_found

duration="$(($(date +%s) - tsaft_start))"
display_time_elapsed "$duration" "Setup Final tasks"

deploy_state_clear

msg_1 "This system has completed the last deploy steps and is ready!"
echo
cd || error_msg "Failed to cd home"
