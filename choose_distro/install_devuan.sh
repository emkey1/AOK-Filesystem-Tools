#!/bin/sh
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#  shellcheck disable=SC2114

. /opt/AOK/tools/utils.sh

ensure_bootstrap_tools() {
    hostfs_is_alpine || return

    msg_2 "Installing Devuan bootstrap tools into Alpine"
    apk add debootstrap perl wget ca-certificates || {
        error_msg "Failed to install Devuan bootstrap tools"
    }
    command -v update-ca-certificates >/dev/null 2>&1 && {
        update-ca-certificates >/dev/null 2>&1
    }
}

ensure_devuan_debootstrap_script() {
    debootstrap_script_dir=/usr/share/debootstrap/scripts
    debootstrap_script="$debootstrap_script_dir/$devuan_suite"
    script_source="$debootstrap_script_dir/ceres"
    keyring_devuan=/usr/share/keyrings/devuan-archive-keyring.gpg
    keyring_debian=/usr/share/keyrings/debian-archive-keyring.gpg

    if [ ! -f "$debootstrap_script" ]; then
        [ -f "$script_source" ] || {
            error_msg "No usable debootstrap source script found for Devuan ($devuan_suite)"
        }

        msg_2 "Creating debootstrap script for Devuan $devuan_suite"
        cp "$script_source" "$debootstrap_script" || {
            error_msg "Failed to create debootstrap script: $debootstrap_script"
        }
        chmod 755 "$debootstrap_script" || {
            error_msg "Failed to chmod debootstrap script: $debootstrap_script"
        }
    fi

    if [ -f "$keyring_devuan" ]; then
        sed -i "s|$keyring_debian|$keyring_devuan|g" "$debootstrap_script" || {
            error_msg "Failed to adjust keyring in: $debootstrap_script"
        }
    else
        msg_3 "Devuan archive keyring not present on Alpine host"
        msg_3 "bootstrap may need the no-check-gpg fallback"
    fi
}

bootstrap_devuan_rootfs() {
    distro_tmp_dir="/Devuan"
    devuan_suite="${DEVUAN_SUITE:-daedalus}"
    devuan_arch="${DEVUAN_ARCH:-i386}"
    devuan_mirror="${DEVUAN_MIRROR:-http://deb.devuan.org/merged}"

    msg_1 "Bootstrapping Devuan $devuan_suite"
    msg_3 "arch: $devuan_arch"
    msg_3 "mirror: $devuan_mirror"
    ensure_devuan_debootstrap_script
    msg_3 "script: $debootstrap_script"

    rm -rf "$distro_tmp_dir"
    mkdir -p "$distro_tmp_dir" || {
        error_msg "Failed to create bootstrap target: $distro_tmp_dir"
    }

    debootstrap --variant=minbase --arch="$devuan_arch" \
        "$devuan_suite" "$distro_tmp_dir" "$devuan_mirror" \
        "$debootstrap_script" || {
        msg_2 "debootstrap failed, retrying without GPG verification"
        rm -rf "$distro_tmp_dir"
        mkdir -p "$distro_tmp_dir" || {
            error_msg "Failed to recreate bootstrap target: $distro_tmp_dir"
        }
        debootstrap --variant=minbase --no-check-gpg --arch="$devuan_arch" \
            "$devuan_suite" "$distro_tmp_dir" "$devuan_mirror" \
            "$debootstrap_script" || {
            error_msg "Devuan bootstrap failed"
        }
    }
}

tid_start="$(date +%s)"

msg_script_title "install_devuan.sh  Bootstrapping & Installing Devuan"

#
#  Step 1  Bootstrap Devuan into a temporary rootfs
#
ensure_bootstrap_tools
bootstrap_devuan_rootfs

cd / || error_msg "Failed to cd into: /"

msg_3 "Maintaining resolv.conf"
cp -a /etc/resolv.conf "$distro_tmp_dir"/etc

msg_3 "maintaining /etc/opt"
cp -a /etc/opt "$distro_tmp_dir"/etc

msg_2 "Moving FamDeb /etc/profile into place"
cp /opt/AOK/FamDeb/etc/profile "$distro_tmp_dir"/etc/profile

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
/busybox mv "$distro_tmp_dir"/srv /
/busybox mv "$distro_tmp_dir"/usr /
/busybox mv "$distro_tmp_dir"/var /
/busybox mv "$distro_tmp_dir"/etc /

#  From now on Devuan should be fully available

rm -f "$f_destfs_select_hint"

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
