#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Completes the setup of Debian
#  On normal installs, this runs at the end of the install.
#  On pre-builds this will be run on first boot at destination device,
#  so it can be assumed this is running on deploy destination
#

#===============================================================
#
#   Main
#
#===============================================================

[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh

if this_is_ish && ! this_is_aok_kernel; then
    msg_2 "Replacing uptime on regular iSH kernel"
    mv /usr/bin/uptime /usr/bin/org-uptime
    rsync_chown /opt/AOK/Debian/ish_replacement_bins/uptime /usr/bin
else
    msg_2 "Devuan uptime works on this env"
fi
