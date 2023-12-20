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
_f="/etc/issue"
if [ ! -e "$_f" ]; then
    /usr/local/bin/fake_syslog ensure_issue_exists touching "$_f"
    /bin/touch "$_f"
fi
