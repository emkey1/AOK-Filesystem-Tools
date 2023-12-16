#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Cleans up a Debian10-minim-x image ready to be used to create an
#  Debian10-x-aok-y image
#

d_here="$(dirname "$0")"

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
