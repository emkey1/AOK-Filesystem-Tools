#!/bin/sh

copy_doing_backup() {
    f_src="$1"
    f_dst="$2"

    if [ -z "$f_src" ]; then
        echo "ERROR: copy_doing_backup() - No src param!"
        exit 1
    fi
    if [ -z "$f_dst" ]; then
        echo "ERROR: copy_doing_backup() - No dest param!"
        exit 1
    fi

    if [ ! -f "$f_src" ]; then
        echo "ERROR: copy_doing_backup() - src not found: $f_src"
        exit 1
    fi

    echo "Copying $f_src -> $f_dst"
    if [ -f "$f_dst" ]; then
        f_bu="$f_dst".old
        echo "  Creating backup: $f_bu"
        mv "$f_dst" "$f_bu" || {
            echo "ERROR: Failed to create BU: $f_dst - $f_bu"
            echo "       Need sudo?"
            exit 1
        }
    fi

    cp "$f_src" "$f_dst" || {
        echo "ERROR: Failed to copy $f_src - $f_dst"
        echo "       Need sudo?"
        exit 1
    }
}

deploy_2_etc() {
    # echo "Would do deploy_2_etc -> $mount_point/etc" ; return

    mkdir -p "$mount_point/etc/bash"
    copy_doing_backup etc/bash/bashrc "$mount_point"/etc/bash/bashrc

    mkdir -p "$mount_point/etc/zsh"
    copy_doing_backup etc/zsh/zlogin "$mount_point"/etc/zsh/zlogin
    copy_doing_backup etc/zsh/zlogout "$mount_point"/etc/zsh/zlogout
    copy_doing_backup etc/zsh/zprofile "$mount_point"/etc/zsh/zprofile
    copy_doing_backup etc/zsh/zshenv "$mount_point"/etc/zsh/zshenv
    copy_doing_backup etc/zsh/zshrc "$mount_point"/etc/zsh/zshrc

    copy_doing_backup etc/bash.bashrc "$mount_point"/etc/bash.bashrc
    copy_doing_backup etc/profile "$mount_point"/etc/profile
    copy_doing_backup etc/zprofile "$mount_point"/etc/zprofile
    copy_doing_backup etc/zshenv "$mount_point"/etc/zshenv
    copy_doing_backup etc/zshrc "$mount_point"/etc/zshrc
}

deploy_2_home_dir() {
    # echo "Would do deploy_2_home_dir -> $home_dir" ; return

    copy_doing_backup home_dir/.ash_init "$home_dir"/.ash_init
    copy_doing_backup home_dir/.bash_login "$home_dir"/.bash_login
    copy_doing_backup home_dir/.bash_logout "$home_dir"/.bash_logout
    copy_doing_backup home_dir/.bash_profile "$home_dir"/.bash_profile
    copy_doing_backup home_dir/.bashrc "$home_dir"/.bashrc
    copy_doing_backup home_dir/.env_init "$home_dir"/.env_init
    copy_doing_backup home_dir/.profile "$home_dir"/.profile
    copy_doing_backup home_dir/.shinit "$home_dir"/.shinit
    copy_doing_backup home_dir/.zlogin "$home_dir"/.zlogin
    copy_doing_backup home_dir/.zlogout "$home_dir"/.zlogout
    copy_doing_backup home_dir/.zprofile "$home_dir"/.zprofile
    copy_doing_backup home_dir/.zshenv "$home_dir"/.zshenv
    copy_doing_backup home_dir/.zshrc "$home_dir"/.zshrc
}

#===============================================================
#
#   Main
#
#===============================================================

d_init_order=$(cd -- "$(dirname -- "$0")" && pwd)
mount_point="$1"
location="$2"
t_real_fs_delay=5

#
#  For the rest of this to be simple, asume this is run from within
#  this folder, even if run using full path from another location
#
cd "$d_init_order" || {
    echo "ERROR: failed to cd into $d_init_order"
    exit 1
}

if [ -z "$mount_point" ]; then
    echo "First param must be mount_point, if it should be deployed"
    echo "to the current FS use /"
    exit 1
elif [ ! -d "$mount_point" ]; then
    echo "Mount point not found: [$mount_point]"
    exit 1
fi

home_dir="$(echo "$mount_point/$location" | sed 's#//#/#')"
if [ -z "$location" ]; then
    echo "ERROR: Second param missing!"
    echo "it is home_dir, relative to mount_point (param 1)"
    exit 1
elif [ ! -d "$home_dir" ]; then
    echo "Destination not found: [$home_dir]"
    exit 1
fi

if [ "$mount_point" = "/" ]; then
    echo
    echo "***  WARNING  ***"
    echo
    echo "This will replace init files in the current File System!"
    echo
    echo "Waiting $t_real_fs_delay seconds, in order for you to abort"
    echo "if this was in mistake..."
    echo
    sleep "$t_real_fs_delay"
fi

#
#  Doing etc first, it will capture missing file privs before messing
#  with the home dir
#
deploy_2_etc

deploy_2_home_dir
