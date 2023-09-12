#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Populates a Debian10-minim-x image into an Debian10-x-aok-y
#

#
#  Since the minim FS comes with caches cleared, an apt update
#  is needed to repopulate the cache for the packet manager
#
apt update

#
# Packages to add in order to create an AOK style image
#
pkgs_tools="coreutils findutils util-linux psmisc
  file gawk grep less sed sudo tar tzdata
  manpages man-db
  fzf git htop ncdu python3-pip sqlite"

pkgs_devel="build-essential autoconf automake bison flex"

pkgs_net_tools="openssl openssh-client openssh-server
  curl elinks git mosh rsync wget" # mtr - causes tons of depenencies..

pkgs_services="openrc cron"

pkgs_shells="bash zsh"

pkgs_editing="vim nano mg" # mg is a lightweight emacs

pkgs_text_ui="ncurses-bin whiptail tmux"

pkgs_other="fortune-mod"

CORE_APTS="$pkgs_tools $pkgs_devel $pkgs_net_tools $pkgs_services
  $pkgs_shells $pkgs_editing $pkgs_text_ui $pkgs_other"

#  shellcheck disable=SC2086
apt install -y $CORE_APTS

#
#  Remove stuff not needed by iSH
#
apt purge -y dirmngr gnupg-l10n gnupg-utils gpg gpgconf gpgsm libapparmor1 \
  libdbus-1-3 libelogind0 libxau6 libxcb1 libxext6 libx11-6 libx11-data \
  libxmuu1 pinentry-curses python3-asn1crypto python3-cffi-backend \
  python3-cryptography python3-dbus python3-entrypoints xauth xdg-user-dirs

#
#  Remember to run Mapt once this is done!
#
