#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Cleans up the FS AOK uses to generate Debian imgs
#

d_here="$(dirname "$0")"

echo
echo "=== Ensure apt is in good health"
echo
"$d_here"/Mapt

echo
echo "=== Cleanout log files"
echo
cd /var/log

rm -f alternatives.log
rm -rf apt
rm -f dpkg.log
rm -f dmesg*
rm -f lastlog
rm -f oddlog

echo "After you exit the chroot"
echo "1. Clear out tmp using something like:"
echo "   rm -rf [mountpoint]/tmp/*"
echo
echo "2. Depending on privacy concerns, since this image is typically"
echo "   made available for public download, consider to check"
echo "   [mountpont]/root/.bash_history"
echo
