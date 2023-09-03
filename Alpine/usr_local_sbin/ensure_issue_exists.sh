#!/bin/sh
#
#  shellcheck disable=SC2154
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Login crashes if /etc/issue is not pressent.
#  This ensures at least an empty file is there
#
if [ ! -e /etc/issue ]; then
    /bin/touch /etc/issue
fi
