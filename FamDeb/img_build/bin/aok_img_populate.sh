#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  What is said here for Debian, also goes for Devuan
#
#  Populates a Debian10-minim-x image into an Debian10-x-aok-y ready to
#  be used to build an AOK-Filesystems-Tools Debian10 image
#
#  This populates the Debian image to have as far as possible, the
#  same things installed, as would be on an Alpine deploy.
#
#  Since adding the default software during deploy in a Debian running
#  inside iSH is quite slow, for Debian everything is installed by
#  default, so items not wanted will have to instead be removed.
#
aipop_time_start="$(date +%s)"
aiprop_prog_name=$(basename "$0")
d_here="$(dirname "$0")"

. /opt/AOK/tools/utils.sh
# shellcheck source=/dev/null
. "$d_here"/img_build_utils.sh

#
#  Since the minim FS comes with caches cleared, an apt update
#  is needed to repopulate the cache for the packet manager
#
# msg_1 "Do update in cashe caches are gone"
# apt update

#
#  This needs to be synced with AOK_VARS from time to time, to ensure
#  the Debian install is as similar as possible to the Alpine
#
# Packages to add in order to create an AOK style image
#
msg_1 "Install AOK-FS packages"

#
#  man is not installed by deafult, since anytime an apt with a man page
#  is installed and man is pressent, a trigger to rebuld the man pages
#  are run, and on iSH it takes a loong time...
#  if man is indeed wanted, do: apt install man-db
#
pkg_busybox="bc dnsutils lsof tree"
pkgs_tools="psmisc coreutils procps util-linux
    sudo tzdata findutils sed tar pigz file gawk
    grep htop less sqlite3 fzf python3-pip ncdu"
pkgs_shells="bash zsh"
pkgs_services="openrc cron"
pkgs_net_tools="openssh-client openssh-server git rsync curl wget elinks mosh"
pkgs_editing="vim nano mg"
pkgs_text_ui="ncurses-bin whiptail tmux"
pkgs_other="fortune-mod" # make sure /usr/games is in PATH

# pkgs_devel="build-essential cmake automake autoconf bison flex"
CORE_APTS="$pkg_busybox $pkgs_tools $pkgs_shells $pkgs_services
    $pkgs_net_tools $pkgs_editing $pkgs_text_ui $pkgs_other"

#  shellcheck disable=SC2086
apt install -y $CORE_APTS || error_msg "apt install issue"
health_check

# purges="exim4-config shared-mime-info"
# # fontconfig related
# purges="$purges adwaita-icon-theme at-spi2-core fontconfig
#     fontconfig-config fonts-dejavu-core
#     libgdk-pixbuf-2.0-0:i386 libgtk-3-common x11-common
# "

# msg_1 "Remove stuff not needed by iSH-AOK"
# #  shellcheck disable=SC2086
# apt purge -y $purges
# health_check

disable_services

# rmdir_if_only_uuid /usr/local/share/fonts
# rmdir_if_only_uuid /usr/share/fonts/truetype/dejavu
# rmdir_if_only_uuid /usr/share/fonts/truetype
# rmdir_if_only_uuid /usr/share/fonts

health_check

duration="$(($(date +%s) - aipop_time_start))"
display_time_elapsed "$duration" "$aiprop_prog_name"

next_task="$d_here"/aok_img_cleanup.sh
msg_1 "aok_img_populate.sh done - chaining to $next_task"
$next_task
