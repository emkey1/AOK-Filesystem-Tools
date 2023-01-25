#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

#
#  Needed in order to find dialog/newt in case they have been updated
#
msg_3 "apk update & upgrade"
apk update && apk upgrade

msg_3 "Installing newt (whiptail) & wget (needed for Debian download)"
apk add newt wget

# shellcheck disable=SC2154
bldstat_set "$status_select_distro_prepared"

select_task "$setup_select_distro"

if bldstat_get "$status_is_chrooted"; then
    echo "This is chrooted, doesn't make sense to select Distro"
    touch /opt/post_boot_done
fi