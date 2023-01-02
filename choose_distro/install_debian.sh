#!/bin/sh
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#  shellcheck disable=SC2114,SC2154

#  shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV

tid_start="$(date +%s)"

#
#  Ensure all devs are in a good state.
#  Since it is not installed yet in /usr/local/sbin, run it from source
#  It wil be deployed in SETUP_COMMON_AOK
#
if is_ish; then
    # Don't bother if just chrooted
    "$AOK_CONTENT"/common_AOK/usr_local_sbin/fix_dev
fi

msg_1 "Installing Debian"

#
#  Step 1  Download and upack Debian
#

debian_download_location="/tmp/debian_fs"

mkdir -p "$debian_download_location"

cd "$debian_download_location" || exit 99

msg_2 "Downloading $DEBIAN_TARBALL"
wget "$DEBIAN_TARBALL"

msg_2 "Extracting Debian (will show unpack time)"
mkdir -p /Debian
cd /Debian || exit 98
time tar xfj "$debian_download_location"/*
cd /
msg_3 "Extracted Debian tarball"

msg_3 "maintaining resolv.conf"
cp -av /etc/resolv.conf /Debian/etc

msg_3 "maintaining /etc/opt"
cp -av /etc/opt /Debian/etc

msg_2 "Moving Debian /etc/profile into place"
cp "$AOK_CONTENT"/Debian/etc/profile /Debian/etc/profile

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

rm /usr -rf
rm /var -rf
rm /sbin -rf
rm /home -rf
rm /etc -rf
rm /media -rf
rm /mnt -rf
rm /root -rf
rm /run -rf
rm /srv -rf

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

/busybox mv /Debian/bin /
/busybox mv /Debian/sbin /
/busybox mv /Debian/home /
/busybox mv /Debian/lib64 /
/busybox mv /Debian/libx32 /
/busybox mv /Debian/media /
/busybox mv /Debian/mnt /
/busybox mv /Debian/root /
/busybox mv /Debian/run /
/busybox mv /Debian/srv /
/busybox mv /Debian/usr /
/busybox mv /Debian/var /
/busybox mv /Debian/etc /

# /busybox echo "-> Copying Alpine lib (musl) to /usr/lib"
msg_3 "Copying Alpine lib (musl) to /usr/lib"
/busybox cp /lib/* /usr/lib

#  replace /lib with soft-link to /usr/lib
# /busybox echo "> Replacing /lib with a soft-link to /usr/lib"
msg_3 "Replacing /lib with a soft-link to /usr/lib"
"$AOK_CONTENT"/choose_distro/bin/lib_fix

#  From now on Debian should be fully available

msg_3 "Removing tmp area /Debian"
rm /Debian -rf

msg_2 "Removing last traces of Alpine - busybox"
rm /busybox
rm /usr/lib/libc.musl*
rm /usr/lib/ld-musl*

"$SETUP_DEBIAN"

duration="$(($(date +%s) - tid_start))"
display_time_elapsed "$duration" "Debian install"
