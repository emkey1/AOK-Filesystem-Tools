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

show_help() {
    echo "Usage: $prog_name debian|devuan

This unpacks a disk image, and copies into it the img_build stuff
"
}

#===============================================================
#
#   Main
#
#===============================================================

d_base=/mnt/HC_Volume_36916115/aok_tmp
prog_name=$(basename "$0")

hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh

[ -z "$1" ] && {
    show_help
    error_msg "Missing param indicating intended File System"
}

_s="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
case "$_s" in
-h | --help)
    show_help
    exit 0
    ;;
debian | deb) img_type="Debian" ;;
devuan | devu | dev) img_type="Devuan" ;;
*) error_msg "Bad param: $_s" ;;
esac

#
#  Read config settings
#
# shellcheck source=/dev/null
. /opt/AOK/"$img_type"/img_build.conf || {
    error_msg "Failed to read img_build conf for Debian"
}
[ -z "$d_ish_FS" ] && error_msg "d_ish_FS config missing!"
[ -z "$f_deb_img" ] && error_msg "f_deb_img config missing!"

# d_ish_FS="$d_base"/Devuan5-minim-3
# f_deb_img=/home/jaclu/cloud/Dropbox/aok_images/Devuan5-minim-3.tgz

cd "$d_base" || {
    error_msg "Failed cd $d_base"
}

msg_3 "Clearing $d_ish_FS"
rm -rf "$d_ish_FS" || {
    error_msg "Failed to clear $d_ish_FS"
}

msg_3 "Creating $d_ish_FS"
mkdir "$d_ish_FS" || {
    error_msg "Failed to mkdir $d_ish_FS"
}

msg_3 "cd into $d_ish_FS"
cd "$d_ish_FS" || {
    error_msg "Failed cd $d_ish_FS"
}

untar_file "$f_deb_img"

msg_3 "Copy /opt/aok"
rsync_chown /opt/AOK "$d_ish_FS"/opt silent
_f="$d_ish_FS"/opt/AOK/.AOK_VARS
[ -f "$_f" ] && {
    msg_4 "Removing $_f"
    rm -f "$_f"
}

msg_3 "Copying img_build -> $d_ish_FS/root"
rsync_chown /opt/AOK/FamDeb/img_build "$d_ish_FS"/root silent
msg_4 "Copying Mapt to img_build/bin"
rsync_chown /opt/AOK/common_AOK/usr_local_bin/Mapt "$d_ish_FS"/root/img_build/bin silent

msg_3 "copying skels -> $d_ish_FS/root"
rsync_chown /opt/AOK/common_AOK/etc/skel/ "$d_ish_FS"/root silent

msg_3 "Adding img_build to PATH"
echo "export PATH=\"/root/img_build/bin:$PATH\"" >>"$d_ish_FS"/root/.common_rc

#
#  Ensuring .bash_logout isn't present
#
_f="$d_ish_FS"//etc/skel/.bash_logout
[ -f "$_f" ] && {
    msg_3 "Removing $_f"
    rm "$_f"
}
_f="$d_ish_FS"//etc/skel/.bash_logout
[ -f "$_f" ] && {
    msg_3 "Removing $_f"
    rm "$_f"
}
msg_2 "chrooting into the image"
/opt/AOK/tools/do_chroot.sh -p "$d_ish_FS"
