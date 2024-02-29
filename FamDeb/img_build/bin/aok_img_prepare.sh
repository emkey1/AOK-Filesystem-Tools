#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  Populates a Devuan5-minim-x image into an Devuan-x-aok-y ready to
#  be used to build an AOK-Filesystems-Tools Devuan image
#
#  This populates the Devuan image to have as far as possible, the
#  same things installed, as would be on an Alpine deploy.
#
#  Since adding the default software during deploy in a Devuan running
#  inside iSH is quite slow, for Devuan everything is installed by
#  default, so items not wanted will have to instead be removed.
#

d_here="$(dirname "$0")"

. /opt/AOK/tools/utils.sh

#
#  Since the minim FS comes with caches cleared, an apt update
#  is needed to repopulate the cache for the packet manager
#
msg_1 "Do update in case caches are gone"
apt update

_f=aok_img_populate.sh
msg_1 "Ensure apt is in good health, then chain to $_f"
Mapt && "$d_here/$_f"
