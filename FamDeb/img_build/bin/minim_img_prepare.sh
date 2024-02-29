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

d_here="$(dirname "$0")"

. /opt/AOK/tools/utils.sh
# shellcheck source=/dev/null
. "$d_here"/img_build_utils.sh

msg_1 "Doing apt update"
apt update

msg_1 "Removing stuff that should not be here"
rm -f /etc/aok_release # obsolete file that might be around in some minim files

pkgs_purge="groff-base file pigz less curl rsync sqlite3 tinysshd vim
    vim-runtime x11-common sysv-rc fontconfig-config fontconfig
    fonts-dejavu-core at-spi2-core libfontconfig1 libmagic1:i386"
echo "   $pkgs_purge"
#  shellcheck disable=SC2086
apt purge -y $pkgs_purge

health_check

msg_1 "Ensure some basic tools are installed"
apt install -y bc sed gawk grep locales findutils lsb-release

# msg_1 "Create db over installed packages grouped by sections"
# echo "this last step can be aborted with Ctrl-C"
# echo
# /root/img_build/bin/package_info_to_db.sh
