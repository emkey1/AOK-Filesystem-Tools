#!/bin/sh
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#
#
#  This should be run inside the env, either chrooted or during deploy
#

# shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV

setup_environment() {
    msg_2 "Setting up environment"

    #  Announce what AOK release this is
    echo "$AOK_VERSION" > "$FILE_AOK_RELEASE"

    cp "$AOK_CONTENT"/common_AOK/etc/motd_template /etc

    sed "s/AOK_VERSION/$AOK_VERSION/" "$AOK_CONTENT"/common_AOK/etc/issue > /etc/issue

    msg_3 "Populate /etc/skel"
    cp -av "$AOK_CONTENT"/common_AOK/etc/skel /etc

    # Move sshd to port 1022 to avoid issues
    sshd_port=1022
    msg_3 "sshd will use port: $sshd_port"
    sed -i "/Port /c\Port $sshd_port" /etc/ssh/sshd_config
    #sed -i "s/.*Port .*/Port $sshd_port/" /etc/ssh/sshd_config

    msg_3 "Add our common stuff to /usr/local/bin"
    cp "$AOK_CONTENT"/common_AOK/usr_local_bin/* /usr/local/bin
    chmod +x /usr/local/bin/*

    msg_3 "Add our common stuff to /usr/local/sbin"
    cp "$AOK_CONTENT"/common_AOK/usr_local_sbin/* /usr/local/sbin
    chmod +x /usr/local/sbin/*


    msg_3 "Activating group sudo for no passwd sudo"
    cp "$AOK_CONTENT"/common_AOK/etc/sudoers.d/sudo_no_passwd /etc/sudoers.d
    chmod 440 /etc/sudoers.d/sudo_no_passwd

    #
    #  If chrooted inside tmux TERM causes whiptail to fail, set it to something
    #  safe.
    #
    TERM=xterm

    #
    #  Need full path to handle that this path is not correctly cached at
    #  this point if Debian is being installed, probably due to switching
    #  from Alpine to Debian without having rebooted yet.
    #
    if [ -n "$AOK_TIMEZONE" ]; then
        msg_2 "Using hardcoded TZ: $AOK_TIMEZONE"
        ln -sf "/usr/share/zoneinfo/$AOK_TIMEZONE" /etc/localtime
    else
        /usr/local/bin/set-timezone
    fi
}



setup_login() {
    if [ -f /etc/debian_version ]; then
        # -> For now Debian login is not altered
        return
    fi
    #
    #  What login method will be used is setup during FIRST_BOOT,
    #  at this point we just ensure everything is available and initial boot
    #  will use the default loging that should work on all platforms.
    #
    msg_2 "Install AOK login methods"
    cp "$AOK_CONTENT"/Alpine/bin/login.loop /bin
    chmod +x /bin/login.loop
    cp "$AOK_CONTENT"/Alpine/bin/login.once /bin
    chmod +x /bin/login.once

    #
    #  Save the original login, if it was not just a soft-link
    #
    if [ -x /bin/login ] && [ ! -L /bin/login ]; then
        #  If it is a file, assume it to be the shadow login binary, save it
        #  so that it can be selected later
        mv /bin/login "$LOGIN_ORIGINAL"
    fi

    #  For now use a safe method, if supported the requested method will be
    #  setup towards the end of the setup process
    ln -sf /bin/busybox /bin/login
}


copy_skel_files() {
    dest="$1"
    if [ -z "$dest" ]; then
        error_msg "copy_skel_files() needs a destination param"
    fi
    rsync -a /etc/skel/ "$dest"
    cd "$dest" || exit 99
    ln -sf .bash_profile .bashrc
}


user_root() {
    msg_2 "Setting up root user env"

    #
    #  Change roots shell
    #
    sed -i 's/\/bin\/ash$/\/bin\/bash/' /etc/passwd

    #
    #  root user env
    #
    copy_skel_files /root
    chown -R root: /root
}

user_ish() {
    msg_2 "Creating the ish user and group"

    groupadd -g 501 ish

    # temp changing UID_MIN is to silence the warning:
    # ish's uid 501 outside of the UID_MIN 1000 and UID_MAX 6000 range.
    #  add additional groups with -G
    useradd -m -s /bin/bash -u 501 -g 501 -G sudo,root,adm ish --key UID_MIN=501

    # shadow with blank ish password
    sed -i "s/ish:\!:/ish::/" /etc/shadow

    # Add dot files for ish
    copy_skel_files ~ish

    mkdir ~ish/Docs
    cp -r "$AOK_CONTENT"/Docs/* ~ish/Docs

    # set ownership
    chown -R ish: ~ish
}


setup_environment
setup_login
user_root
user_ish
