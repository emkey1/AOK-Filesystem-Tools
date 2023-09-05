#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Populates a Debian10-minim-x image into an Debian10-x-aok-y
#

#
# Packages to add in order to create an AOK style image
#
pkgs_tools="coreutils util-linux sudo tzdata findutils sed tar
  file gawk grep less git sqlite fzf python3-pip ncdu
  manpages man-db psmisc whiptail htop"
pkgs_shells="bash zsh"
pkgs_services="openrc" # not sure what cron to use

# mtr is used on Alpine but on Debian it causes tons of depenencies..
pkgs_net_tools="openssl openssh-client openssh-server rsync curl
  wget elinks mosh"

pkgs_editing="vim nano mg"
pkgs_text_ui="ncurses-bin whiptail tmux"
pkgs_other="fortune-mod"

CORE_APTS="$pkgs_tools $pkgs_shells $pkgs_services $pkgs_net_tools
  $pkgs_editing $pkgs_text_ui $pkgs_other"

#  shellcheck disable=SC2086
apt install -y $CORE_APTS

#
#  Remove stuff not usable or needed when running on iSH
#  this also removes quite a few dependencies
#
delay=5
echo
echo
echo "=====   wil purge in $delay   ====="
sleep "$delay"

apt purge -y dbus dirmngr elogind gnupg-l10n gnupg-utils gpg gpg-agent gpgconf gpgsm libapparmor1 libdbus-1-3 libelogind0 pinentry-curses python3-asn1crypto python3-cffi-backend python3-cryptography python3-dbus python3-entrypoints xdg-user-dirs

#
#  Remember to
#
#  run Mapt once this is done
#  ensusre no services are active: find /etc/runlevels
#  remmove deploy stuff before conpressing a new Debian10-x-aok-y
#  clear /root/.bash_history
#  clear /root/.viminfo
#
