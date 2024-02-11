#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Populates a Debian10-minim-x image into an Debian10-x-aok-y ready to
#  be used to build an AOK-Filesystems-Tools Debian image
#
#  This populates the Debian image to have as far as possible, the
#  same things installed, as would be on an Alpine deploy.
#
#  Since adding the default software during deploy in a Debian running
#  inside iSH is quite slow, for Debian everything is installed by
#  default, so items not wanted will have to instead be removed.
#
d_here="$(dirname "$0")"

#
#  Since the minim FS comes with caches cleared, an apt update
#  is needed to repopulate the cache for the packet manager
#
echo
echo "=== Do update in case caches are gone"
echo
apt update

echo
echo "=== Disable ssh service"
echo
rc-update del ssh default

echo
echo "=== Ensure apt is in good health"
echo
"$d_here"/Mapt
