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
cd /var/log || {
    echo "ERROR: cd /var/log failed"
    exit 1
}

rm -f alternatives.log
rm -rf apt
rm -f dpkg.log
rm -f dmesg*
rm -f lastlog
rm -f oddlog

#
#  Update aok-fs-release
#
f_aok_fs_release=/etc/aok-fs-release
# aok_fs_release="$(cat "$f_aok_fs_release")"
#
#  TODO: add logic to extract minim_rel both from a minim
#        and a Debian10-X-aok-Y
#
minim_rel="$(cut -d- -f3 "$f_aok_fs_release")"

while [ -z "$rel_vers" ]; do
    echo
    echo "Enter $f_aok_fs_release vers, what follows Debian10-${minim_rel}-aok-"
    read -r rel_vers
done

aok_release="Debian10-${minim_rel}-aok-$rel_vers"
echo "$aok_release" >"$f_aok_fs_release"
echo
echo "$f_aok_fs_release - Set to: $(cat "$f_aok_fs_release")"

echo "After you exit the chroot"
echo "1. Clear out tmp using something like:"
echo "   rm -rf [mountpoint]/tmp/*"
echo
echo "2. Depending on privacy concerns, since this image is typically"
echo "   made available for public download, consider to check"
echo "   [mountpont]/root/.bash_history"
echo
