#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#

# shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV

#
#  Needed in order to find dialog/newt in case they have been updated
#
msg_3 "apk update & upgrade"
apk update && apk upgrade


#
#  Only one of the below is needed, on iSH dialog continues when you hit arrows,
#  so easy to end up picking the wrong one, whiptail seems the better choice
#  for now.
#

# echo "-> installing dialog & wget (needed for Debian download)"
# apk add dialog wget

msg_3 "Installing newt (whiptail) & wget (needed for Debian download)"
apk add newt wget

# shellcheck disable=SC2154
bldstat_set "$STATUS_SELECT_DISTRO_PREPARED"
