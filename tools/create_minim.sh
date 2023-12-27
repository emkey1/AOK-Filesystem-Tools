#!/bin/sh
#  shellcheck disable=SC2154
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2021-2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Creates a workspace for a minim image, used to prepare the base image
#  later used to create an DEBIAN_SRC_IMAGE
#
# _td="$AOK_TMPDIR"
hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
. /opt/AOK/tools/utils.sh
# export AOK_TMPDIR="$_td"

d_unpack="$1" # /opt/minim8
tar_file="$2" # /home/jaclu/cloud/Dropbox/aok_images/Debian10-minim-8.tgz
app_name="$(basename "$0")"

[ -z "$d_unpack" ] && error_msg "$app_name - no first param"
[ -z "$tar_file" ] && error_msg "$app_name - no second param"

#
#  Since this will be unpacked as root, do some extra checks that the
#  unpack location is valid
#
case "$d_unpack" in

"$AOK_TMPDIR"/aok_*)
    error_msg "$app_name param 1 cant start with $AOK_TMPDIR/aok_ - was: $d_unpack"
    ;;
"$AOK_TMPDIR"/*) ;;
*) error_msg "$app_name param 1 must start with $AOK_TMPDIR/ - was: $d_unpack" ;;
esac

[ -f "$tar_file" ] || error_msg "$app_name - tar file not found: $tar_file"

#
#  And action...
#
[ -d "$d_unpack" ] && {
    msg_2 "Erasing previous content from $d_unpack"
    rm "$d_unpack" -rf
}

msg_2 "Creating folder $d_unpack"
mkdir "$d_unpack"

msg_2 "Unpacking $tar_file"
cd "$d_unpack" || error_msg "cd failed - $d_unpack"
tar xfz "$tar_file"

msg_2 "Update img_build"
rsync -ahP --delete /opt/AOK/Debian/img_build "$d_unpack"/root

/opt/AOK/tools/do_chroot.sh -p "$d_unpack" /root/img_build/bin/build_env.sh
