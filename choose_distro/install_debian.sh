#!/bin/sh
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#  shellcheck disable=SC2114

. /opt/AOK/tools/utils.sh

# shellcheck source=/dev/null
. "$d_aok_base"/FamDeb/deb_utils.sh

tid_start="$(date +%s)"

msg_script_title "install_debian.sh  Downloading & Installing Debian"

#
#  Step 1  Download and upack Debian
#

debian_download_location="$TMPDIR/debian_fs"
src_image="$DEBIAN_SRC_IMAGE"
src_tarball="$debian_download_location/$debian_src_tb"

mkdir -p "$debian_download_location"

cd "$debian_download_location" || {
    error_msg "Failed to cd into: $debian_download_location"
}

#
#  If install was aborted and re-attempted, ensure there is no
#  half downloaded image pressent.
#
rm "$debian_download_location"/* -f

msg_2 "Downloading $src_image"
#  Ensure basename for tar ball is used
wget "$src_image" -O "$debian_src_tb"

msg_1 "Extracting Devuan (will show unpack time)"
distro_tmp_dir="/Debian"
create_fs "$src_tarball" "$distro_tmp_dir"

#
#  Clear openrc status
#
rm "$distro_tmp_dir"/run/openrc -rf

msg_3 "Extracted Debian tarball"

cd / || error_msg "Failed to cd into: /"

msg_3 "Maintaining resolv.conf"
cp -a /etc/resolv.conf "$distro_tmp_dir"/etc
msg_3 "maintaining /etc/opt"
cp -a /etc/opt "$distro_tmp_dir"/etc

msg_2 "Moving Debian /etc/profile into place"
cp "$d_aok_base"/Debian/etc/profile "$distro_tmp_dir"/etc/profile

rm -rf "$debian_download_location"

#
#  Step 2, Get rid of Alpine FS
#
msg_2 "Deleting most of Alpine FS"

#
#  Removing anything but musl from /lib
#  Doing this before moving busybox to make things simpler
#
find /lib/ -mindepth 1 -maxdepth 1 | grep -v musl | xargs rm -rf

rm /home -rf
rm /etc -rf
rm /media -rf
rm /mnt -rf
rm /root -rf
rm /run -rf
rm /sbin -rf
rm /srv -rf
rm /usr -rf
rm /var -rf

msg_3 "Moving busybox to root"
#  will be deleted on Debian 1st boot
cp /bin/busybox /

msg_3 "Deleting last parts of Alpine"
/busybox rm /bin -rf
/busybox rm /sbin -rf

#
#  Step 3, Move Debian into place
#
# /busybox echo "-> Putting Debian stuff into place"
msg_3 "Putting Debian stuff into place"

/busybox mv "$distro_tmp_dir"/bin /
/busybox mv "$distro_tmp_dir"/sbin /
/busybox mv "$distro_tmp_dir"/home /
/busybox mv "$distro_tmp_dir"/lib64 /
/busybox mv "$distro_tmp_dir"/libx32 /
/busybox mv "$distro_tmp_dir"/media /
/busybox mv "$distro_tmp_dir"/mnt /
/busybox mv "$distro_tmp_dir"/root /
/busybox mv "$distro_tmp_dir"/run /
/busybox mv "$distro_tmp_dir"/srv /
/busybox mv "$distro_tmp_dir"/usr /
/busybox mv "$distro_tmp_dir"/var /
/busybox mv "$distro_tmp_dir"/etc /

# /busybox echo "-> Copying Alpine lib (musl) to /usr/lib"
msg_3 "Copying Alpine lib (musl) to /usr/lib"
/busybox cp /lib/* /usr/lib

#  replace /lib with soft-link to /usr/lib
# /busybox echo "> Replacing /lib with a soft-link to /usr/lib"
msg_3 "Replacing /lib with a soft-link to /usr/lib"
"$d_aok_base"/choose_distro/bin/lib_fix

#  From now on Debian should be fully available

rm -f "$f_destfs_select_hint"

msg_3 "Removing tmp area $distro_tmp_dir"
rm "$distro_tmp_dir" -rf || {
    error_msg "Failed to clear: $distro_tmp_dir"
}

msg_2 "Removing last traces of Alpine - busybox"
rm /busybox
rm /usr/lib/libc.musl*
rm /usr/lib/ld-musl*

intial_fs_prep_debian

msg_2 "Set openrc to runlevel default"
/usr/sbin/openrc default

"$setup_debian_scr"

duration="$(($(date +%s) - tid_start))"
display_time_elapsed "$duration" "Debian install"
