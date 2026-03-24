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

[ -z "$d_aok_etc" ] && . /opt/AOK/tools/utils.sh

if this_is_aok_kernel; then
    # ish-aok does not need the replacement uptime
    org_uptime=/usr/bin/ORG.uptime
    def_uptime=/usr/bin/uptime
    [ -x "$org_uptime" ] && {
        # reactivate org uptime
        rm -f "$def_uptime"
        mv "$org_uptime" "$def_uptime"
        # finally remove replacement uptime
        rm -f /usr/local/bin/uptime
    }

fi
