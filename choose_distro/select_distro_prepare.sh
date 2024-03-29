#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  select_distro_prepare.sh
#
#  Prepares the Alpine image to show Distribution selection dialog
#

#  Ensure important devices are present
echo "-> Running fix_dev <-"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev ignore_init_check
echo

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

. /opt/AOK/tools/utils.sh

msg_script_title "select_distro_prepare.sh  Prep for distro select"

#
#  Needed in order to find dialog/newt in case they have been updated
#
msg_2 "apk update & upgrade"
apk update && apk upgrade

msg_3 "Installing wget (needed for Debian download)"
apk add wget

set_new_etc_profile "$setup_select_distro"

if this_fs_is_chrooted; then
    msg_2 "This is chrooted"
    msg_3 "It doesn't make sense to select Distro at this time"
    exit 123
else
    msg_2 "System is prepared, now run distro selection"
    "$setup_select_distro"
fi
