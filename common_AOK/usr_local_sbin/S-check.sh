#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2021-2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Intended to be used by inittab tasks, unless single-user-mode is
#  selected, perform intended task
#

f_single_user_mode="/etc/opt/AOK/single-user-mode"

[ -f "$f_single_user_mode" ] && {
    echo "$(date +"%Y-%m-%d %H:%M:%S") Skipped ${*}" >>/var/log/single-user-mode.log
    exit 0
}

"${@}"
