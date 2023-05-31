#!/bin/sh
# dummy shebang, helping linters, this file is sourced

if [ -n "$USER_HOME_DIR" ]; then
    [ ! -f "$USER_HOME_DIR" ] && error_msg "USER_HOME_DIR file not found: $USER_HOME_DIR"
    [ -z "$USER_NAME" ] && error_msg "USER_HOME_DIR defined, but not USER_NAME"
    cd "~$USER_NAME"
    cd ..
    rm -rf "$USER_NAME"
    tar xvfz "$USER_HOME_DIR" || error_msg "Failed to extract USER_HOME_DIR"
fi

if [ -n "$ROOT_HOME_DIR" ]; then
    [ ! -f "$ROOT_HOME_DIR" ] && error_msg "ROOT_HOME_DIR file not found: $ROOT_HOME_DIR"
    rm /root -rf
    cd /
    tar xvfz "$ROOT_HOME_DIR" || error_msg "Failed to extract USER_HOME_DIR"
fi
