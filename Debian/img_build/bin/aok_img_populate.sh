#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Populates a Debian10-minim-x image into an Debian10-x-aok-y ready to
#  be used to build an AOK-Filesystems-Tools Debian image
#
#  This populates the Debian image to have as far as possible, the
#  same things installed, as would be on an Alpine deploy.
#
#  Since adding the default software during deploy in a Debian running
#  inside iSH is quite slow, for Debian everything is installed by
#  default, so items not wanted will have to instead be removed.
#
d_here="$(dirname "$0")"

#
#  Since the minim FS comes with caches cleared, an apt update
#  is needed to repopulate the cache for the packet manager
#
echo
echo "=== Do update in cashe caches are gone"
echo
apt update

#
#  This needs to be synced with AOK_VARS from time to time, to ensure
#  the Debian install is as similar as possible to the Alpine
#
# Packages to add in order to create an AOK style image
#
echo
echo "=== Install what is on an AOK Alpine FS"
echo
#
#  man is not installed by deafult, since anytime an apt with a man page
#  is installed and man is pressent, a trigger to rebuld the man pages
#  are run, and on iSH it takes a loong time...
#  if man is indeed wanted, do: apt install man-db
#
pkgs_tools="psmisc
coreutils procps util-linux sudo tzdata findutils sed tar
file gawk grep htop less  sqlite fzf python3-pip ncdu"
pkgs_shells="bash zsh"
pkgs_services="openrc cron"
# pkgs_net_tools - openssl?
pkgs_net_tools="openssh-client openssh-server git rsync curl wget
elinks mosh"
pkgs_editing="vim nano mg"
pkgs_text_ui="ncurses-bin whiptail tmux"
pkgs_other="fortune-mod" # make sure /usr/games is in PATH
x_pkgs_devel="build-essential cmake automake autoconf bison flex"
CORE_APTS="$pkgs_tools $pkgs_shells $pkgs_services $pkgs_net_tools \
    $pkgs_editing $pkgs_text_ui $pkgs_other"

#  shellcheck disable=SC2086
apt install -y $CORE_APTS

echo
echo "=== Remove stuff not needed by iSH"
echo
apt purge -y dirmngr gnupg-l10n gnupg-utils gpg gpgconf gpgsm libapparmor1 \
  libdbus-1-3 libelogind0 libxau6 libxcb1 libxext6 libx11-6 libx11-data \
  libxmuu1 pinentry-curses python3-asn1crypto python3-cffi-backend \
  python3-cryptography python3-dbus python3-entrypoints xauth xdg-user-dirs

echo
echo "=== Disable ssh service"
echo
rc-update del ssh default

echo
echo "=== Ensure apt is in good health"
echo
"$d_here"/Mapt
