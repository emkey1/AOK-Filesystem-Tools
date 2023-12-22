#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Cleans up a the image, making it ready to be saved as
#  a Debian10-minim-x image ready to be used to create an
#  Debian10-x-aok-y image
#

d_here="$(dirname "$0")"
f_aok_fs_release=/etc/aok-fs-release

echo
echo "=== Ensure apt is in good health"
echo
"$d_here"/Mapt

echo
echo "=== Cleanout log files"
echo
rm -f /var/log/alternatives.log
rm -rf /var/log/apt
rm -f /var/log/dpkg.log

rm -rf /tmp/*

#
#  Normally you never need to do apt update, but by removing all the
#  apt cache data, the deploy needs to do apt update first, in order
#  to recreate the caches. Running apt upgrade without this apt update
#  will cause it to fail
#
echo
echo "=== Remove apt caches"
echo
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/*
rm -rf /var/cache/debconf/*
rm -rf /var/cache/man/*

while [ -z "$rel_vers" ]; do
    echo
    echo "Enter $f_aok_fs_release vers, what follows Debian-mini-"
    read -r rel_vers
done

aok_release="Debian-mini-$rel_vers"
echo "$aok_release" >/"$f_aok_fs_release"
echo
echo "$f_aok_fs_release - Set to: $aok_release"
