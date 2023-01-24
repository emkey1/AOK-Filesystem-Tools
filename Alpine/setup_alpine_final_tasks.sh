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

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

msg_1 "Running first boot tasks on prebuilt Alpine FS"

if ! is_aok_kernel; then
    msg_2 "Removing apps that depend on the iSH-AOK kernel"
    #
    #  aok dependent bins serve no purpose on other platforms, delete
    #
    # shellcheck disable=SC2086
    apk del $AOK_APKS
fi

bldstat_clear "$status_being_built"

clear_task

run_additional_tasks_if_found

msg_1 "This system has completed the last deploy steps and is ready"
msg_1 "Please reboot / restart app to start using it!"
#  In order for this exit not to terminate the session instantly
#  a shell is started, to give an option to inspect the deploy
#  outcome.
#  If this FS is pre-built this should not happen.
/bin/ash
exit
