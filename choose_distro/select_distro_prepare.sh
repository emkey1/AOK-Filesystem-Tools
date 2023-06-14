#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Prepares the Alpine image to show Distribution selection dialog
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

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

msg_script_title "select_distro_prepare.sh  Prep for distro select"

#
#  Needed in order to find dialog/newt in case they have been updated
#
msg_2 "apk update & upgrade"
apk update && apk upgrade

msg_3 "Installing wget (needed for Debian download)"
apk add wget

# shellcheck disable=SC2154
bldstat_set "$status_select_distro_prepared"

# shellcheck disable=SC2154
select_profile "$setup_select_distro"

# shellcheck disable=SC2154
if is_chrooted; then
    msg_1 "This is chrooted"
    echo "It doesn't make sense to select Distro at this time"
    exit
else
    msg_2 "System is prepared, now run distro selection"
    "$setup_select_distro"
fi
