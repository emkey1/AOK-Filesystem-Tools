#!/bin/sh
#  shellcheck disable=SC2154
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Prepare the minimal FS, try to remove any items really not indented
#  to be here
#

echo
echo "=== Doing apt update"
echo
apt update

echo
echo "=== Removing stuff that should not be here"
echo
rm -f /etc/aok_release
apt purge -y man-db groff-base

echo
echo "=== Do upgrade and apt maintenance"
echo
/root/img_build/bin/Mapt

# echo
# echo "=== Create db over installed packages grouped by sections"
# echo "this last step can be aborted with Ctrl-C"
# echo
# /root/img_build/bin/package_info_to_db.sh
