#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  Cleans up a the image, making it ready to be saved as
#  a Debian10-minim-x image ready to be used to create an
#  Debian10-x-aok-y image
#

d_here="$(dirname "$0")"

. /opt/AOK/tools/utils.sh
# shellcheck source=/dev/null
. "$d_here"/img_build_utils.sh

apt purge -y sqlite3

health_check
update_aok_fs_releae minim
clear_log_tmp
# clear_apt_cache

msg_1 "if image file is saved - clear AOK files!"
echo "  rm /opt/AOK /etc/opt/AOK -rf
"
# remove_aok
