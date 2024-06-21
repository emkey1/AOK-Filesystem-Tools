#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  Cleans up the FS AOK uses to generate Debian/Devuan imgs
#

d_here="$(dirname "$0")"

. /opt/AOK/tools/utils.sh
# shellcheck source=/dev/null
. "$d_here"/img_build_utils.sh

health_check
clear_log_tmp
update_aok_fs_releae
ensure_empty_folder /tmp
ensure_empty_folder /var/tmp
clear_AOK

echo "After you exit the chroot"
echo
echo "1. There will be a warning about /etc/opt/AOK/this_fs_is_chrooted"
echo "   not found. This can be ignored."
echo
echo "2. Consider removing /root/img_build"
echo "   rm -rf [mountpoint]/root/img_build"
echo
echo "3. Depending on privacy concerns, since this image is typically"
echo "   made available for public download, consider to check"
echo "   [mountpont]/root/.bash_history"
echo
echo "4.  tar the FS into a Debian10-x-aok-y.tgz image that can be used"
echo "    with a public url in AOK_VARS to define DEBIAN_SRC_IMAGE"
echo
