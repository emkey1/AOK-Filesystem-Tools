#!/bin/sh
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#  shellcheck disable=SC2114,SC2154

#  shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

tid_start="$(date +%s)"

msg_script_title "install_devuan.sh  Downloading & Installing Devuan"

#
#  Step 1  Download and upack Devuan
#

devuan_download_location="/tmp/devuan_fs"
src_image="$DEVUAN_SRC_IMAGE"
src_tarball="$devuan_download_location/$devuan_src_tb"

mkdir -p "$devuan_download_location"
cd "$devuan_download_location" || {
    error_msg "Failed to cd into: $devuan_download_location"
}

ensure_usable_wget
msg_2 "Downloading $src_image"
wget "$src_image"

t_extract="$(date +%s)"
msg_1 "Extracting Devuan (will show unpack time)"
distro_tmp_dir="/Devuan"
create_fs "$src_tarball" "$distro_tmp_dir"
duration="$(($(date +%s) - t_extract))"
display_time_elapsed "$duration" "Unpacking Devuan"
unset duration

msg_3 "Extracted Devuan tarball"

cd /

msg_3 "Maintaining resolv.conf"
cp -a /etc/resolv.conf "$distro_tmp_dir"/etc

msg_3 "maintaining /etc/opt"
cp -a /etc/opt "$distro_tmp_dir"/etc

msg_2 "Moving Devuan /etc/profile into place"
cp "$aok_content"/Devuan/etc/profile "$distro_tmp_dir"/etc/profile

rm -rf "$devuan_download_location"

#
#  Step 2, Get rid of Alpine FS
#
msg_2 "Deleting most of Alpine FS"
#
#  Removing anything but musl from /lib
#  Doing this before moving busybox to make things simpler
#
find /lib/ -mindepth 1 -maxdepth 1 | grep -v musl | xargs rm -rf

rm /etc -rf
rm /home -rf
rm /media -rf
rm /mnt -rf
rm /root -rf
rm /run -rf
rm /sbin -rf
rm /srv -rf
rm /usr -rf
rm /var -rf

msg_3 "Copying busybox to root"
#  will be deleted on Devuan 1st boot
cp /bin/busybox /

msg_3 "Deleting last parts of Alpine"
/busybox rm /bin -rf
/busybox rm /sbin -rf

#
#  Step 3, Move Devuan into place
#
# /busybox echo "-> Putting Devuan stuff into place"
msg_3 "Putting Devuan stuff into place"

/busybox mv "$distro_tmp_dir"/bin /
/busybox mv "$distro_tmp_dir"/home /
/busybox cp -a "$distro_tmp_dir"/lib /
/busybox mv "$distro_tmp_dir"/media /
/busybox mv "$distro_tmp_dir"/mnt /
/busybox mv "$distro_tmp_dir"/root /
/busybox mv "$distro_tmp_dir"/run /
/busybox mv "$distro_tmp_dir"/sbin /
/busybox mv "$distro_tmp_dir"/search /
/busybox mv "$distro_tmp_dir"/srv /
/busybox mv "$distro_tmp_dir"/usr /
/busybox mv "$distro_tmp_dir"/var /
/busybox mv "$distro_tmp_dir"/etc /

#  From now on Devuan should be fully available

msg_3 "Removing tmp area $distro_tmp_dir"
rm -rf "$distro_tmp_dir" || {
    error_msg "Failed to clear: $distro_tmp_dir"
}

msg_2 "Removing last traces of Alpine - busybox"
rm /busybox
rm /lib/libc.musl*
rm /lib/ld-musl*

"$setup_devuan_scr"

duration="$(($(date +%s) - tid_start))"
display_time_elapsed "$duration" "Devuan install"
