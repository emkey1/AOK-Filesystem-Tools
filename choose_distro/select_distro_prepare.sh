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

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh

msg_script_title "select_distro_prepare.sh  Prep for distro select"

#
#  Needed in order to find dialog/newt in case they have been updated
#
msg_2 "apk update & upgrade"
apk update && apk upgrade

msg_3 "Installing wget (needed for Debian download) & pigz (multicore untar)"
apk add wget pigz

set_new_etc_profile "$setup_select_distro"

if this_fs_is_chrooted; then
    msg_2 "This is chrooted"
    msg_3 "It doesn't make sense to select Distro at this time"
    exit 123
else
    msg_2 "System is prepared, now run distro selection"
    "$setup_select_distro"
fi
