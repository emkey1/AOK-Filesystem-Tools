#!/bin/sh

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

if [ -n "$HOME_DIR_USER" ]; then
    [ ! -f "$HOME_DIR_USER" ] && error_msg "USER_HOME_DIR file not found: $HOME_DIR_USER"
    [ -z "$USER_NAME" ] && error_msg "USER_HOME_DIR defined, but not USER_NAME"
    msg_2 "Replacing /home/$USER_NAME"
    cd "/home"
    rm -rf "$USER_NAME"
    tar xfz "$HOME_DIR_USER" || error_msg "Failed to extract USER_HOME_DIR"
fi

if [ -n "$HOME_DIR_ROOT" ]; then
    [ ! -f "$HOME_DIR_ROOT" ] && error_msg "ROOT_HOME_DIR file not found: $HOME_DIR_ROOT"
    msg_2 "Replacing /root"
    rm /root -rf
    cd /
    tar xfz "$HOME_DIR_ROOT" || error_msg "Failed to extract USER_HOME_DIR"
fi
