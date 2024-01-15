#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Extracts a Deb image, updates img_build in order to prepare new
#
#  Debian10  minim-x / x-aok-y images
#
#  in a structured and repeatable way
#

hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh

d_base=/mnt/HC_Volume_36916115/aok_tmp

d_ish_FS="$d_base"/Debian10-minim-7.1
f_deb_img=/home/jaclu/cloud/Dropbox/aok_images/Debian10-minim-7.1.tgz

cd "$d_base" || {
    error_msg "Failed cd $d_base"
}

msg_3 "clearing $d_ish_FS"
rm -rf "$d_ish_FS" || {
    error_msg "Failed to clear $d_ish_FS"
}

msg_3 "creating $d_ish_FS"
mkdir "$d_ish_FS" || {
    error_msg "Failed to mkdir $d_ish_FS"
}

msg_3 "cd into $d_ish_FS"
cd "$d_ish_FS" || {
    error_msg "Failed cd $d_ish_FS"
}

msg_3 "extracting $f_deb_img"
tar xfz "$f_deb_img" || {
    error_msg "Failed extract $f_deb_img"
}

msg_3 "rsyncing img_build -> $d_ish_FS/root"
rsync -ahP --delete /opt/AOK/Debian/img_build "$d_ish_FS"/root || {
    error_msg "Failed to rsync img_build -> $d_ish_FS/tmp"
}

msg_3 "copying skels -> $d_ish_FS/root"
cp -r /opt/AOK/common_AOK/etc/skel/. "$d_ish_FS"/root || {
    error_msg "Failed to copy skels -> $d_ish_FS/root"
}
