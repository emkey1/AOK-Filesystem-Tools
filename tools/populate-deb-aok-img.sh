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

# Packages to add in order to create an AOK style image

pkgs_tools="coreutils util-linux sudo tzdata findutils sed tar
  file gawk grep less git sqlite fzf python3-pip ncdu
   manpages man-db psmisc whiptail"
pkgs_shells="bash zsh"
pkgs_services="openrc" # not sure what cron to use
pkgs_net_tools="openssl openssh-client openssh-server rsync curl wget elinks mosh"
pkgs_editing="vim nano mg"
pkgs_text_ui="ncurses-bin whiptail tmux"
pkgs_other="fortune-mod"
CORE_APTS="$pkgs_tools $pkgs_shells $pkgs_services $pkgs_net_tools \
    $pkgs_editing $pkgs_text_ui $pkgs_other"

#  shellcheck disable=SC2086
apt install $CORE_APTS

#
# after installing openssh-server, theese redundant packages gets added
#
# apt remove dbus elogind
# apt purge dbus elogind libpam-elogind

# make sure both openssh-client and openssh-server gets installed!
