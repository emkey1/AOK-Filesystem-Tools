#!/bin/sh
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Common setup tasks for both Alpine & Debian
#

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

setup_environment() {

    #  Announce what AOK release this is
    msg_2 "Set $file_aok_release to $AOK_VERSION"
    echo "$AOK_VERSION" >"$file_aok_release"

    msg_2 "copy some /etc files"
    sed "s/AOK_VERSION/$AOK_VERSION/" "$aok_content"/common_AOK/etc/issue >/etc/issue

    if ! command -v sudo >/dev/null; then
        error_msg "sudo not installed, common_AOK/setup_environment() can not complete"
    fi

    if ! command -v bash >/dev/null; then
        error_msg "bash not installed, common_AOK/setup_environment() can not complete"
    fi

    copy_local_bins common_AOK

    #
    #  Need full path to handle that this path is not correctly cached at
    #  this point if Debian is being installed, probably due to switching
    #  from Alpine to Debian without having rebooted yet.
    #
    msg_2 "Setitng time zone"
    if [ -n "$AOK_TIMEZONE" ]; then
        msg_3 "Using hardcoded TZ: $AOK_TIMEZONE"
        ln -sf "/usr/share/zoneinfo/$AOK_TIMEZONE" /etc/localtime
    else
        /usr/local/bin/set-timezone
    fi

    if command -v openrc >/dev/null; then
        msg_2 "Adding runbg service"
        cp -a "$aok_content"/common_AOK/etc/init.d/runbg /etc/init.d
        # openrc_might_trigger_errors
        rc-update add runbg default
    else
        msg_2 "openrc not available - runbg not activated"
    fi

    msg_2 "Populate /etc/skel"
    cp -a "$aok_content"/common_AOK/etc/skel /etc

    if [ -f /etc/ssh/sshd_config ]; then
        if [ "$QUICK_DEPLOY" -eq 0 ]; then
            # Move sshd to port 1022 to avoid issues
            sshd_port=1022
            msg_2 "sshd will use port: $sshd_port"
            sed -i "/Port /c\Port $sshd_port" /etc/ssh/sshd_config
            #sed -i "s/.*Port .*/Port $sshd_port/" /etc/ssh/sshd_config
            unset sshd_port
        else
            msg_2 "QUICK_DEPLOY - skipping changing sshd port"
        fi
    else
        msg_2 "sshd not installed - port not changed"
    fi

    if [ "$QUICK_DEPLOY" -eq 0 ]; then
        msg_2 "Activating group sudo for no passwd sudo"
        cp "$aok_content"/common_AOK/etc/sudoers.d/sudo_no_passwd /etc/sudoers.d
        chmod 440 /etc/sudoers.d/sudo_no_passwd
    else
        msg_2 "QUICK_DEPLOY - skipping no passwd sudo"
    fi

    #
    #  If chrooted inside tmux TERM causes whiptail to fail, set it to something
    #  safe.
    #
    TERM=xterm

}

setup_login() {
    if [ -f "$file_debian_version" ]; then
        # -> For now Debian login is not altered
        return
    fi
    #
    #  What login method will be used is setup during FIRST_BOOT,
    #  at this point we just ensure everything is available and initial boot
    #  will use the default loging that should work on all platforms.
    #
    msg_2 "Install AOK login methods"
    cp "$aok_content"/Alpine/bin/login.loop /bin
    chmod +x /bin/login.loop
    cp "$aok_content"/Alpine/bin/login.once /bin
    chmod +x /bin/login.once

    #
    #  Save the original login, if it was not just a soft-link
    #
    if [ -x /bin/login ] && [ ! -L /bin/login ]; then
        #  If it is a file, assume it to be the shadow login binary, save it
        #  so that it can be selected later
        mv /bin/login "$login_original"
    fi

    #  For now use a safe method, if supported the requested method will be
    #  setup towards the end of the setup process
    ln -sf /bin/busybox /bin/login
}

copy_skel_files() {
    csf_dest="$1"
    if [ -z "$csf_dest" ]; then
        error_msg "copy_skel_files() needs a destination param"
    fi
    cp -r /etc/skel/. "$csf_dest"
    cd "$csf_dest" || {
        error_msg "Failed to cd into: $csf_dest"
    }

    ln -sf .bash_profile .bashrc

    unset csf_dest
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
    msg_3 "clear root history"
    rm /root/.bash_history -f
}

create_user() {
    msg_2 "Creating additional user and group $USER_NAME"
    if [ -z "$USER_NAME" ]; then
        msg_3 "No user requested"
        return
    fi

    cu_home_dir="/home/$USER_NAME"
    groupadd -g 501 "$USER_NAME"

    # temp changing UID_MIN is to silence the warning:
    # ish's uid 501 outside of the UID_MIN 1000 and UID_MAX 6000 range.
    #  add additional groups with -G
    useradd -m -s /bin/bash -u 501 -g 501 -G sudo,root,adm "$USER_NAME" --key UID_MIN=501

    # shadow with blank ish password
    sed -i "s/${USER_NAME}:\!:/${USER_NAME}::/" /etc/shadow

    # Add dot files for ish
    copy_skel_files "$cu_home_dir"

    msg_3 "Adding documentation to userdir"
    cp -a "$aok_content"/Docs "$cu_home_dir"

    # set ownership
    chown -R "$USER_NAME": "$cu_home_dir"

    unset cu_home_dir
}

msg_script_title "setup_common_env.sh  Common AOK setup steps"

setup_environment
setup_login
user_root
if [ "$QUICK_DEPLOY" -eq 0 ]; then
    [ -n "$USER_NAME" ] && create_user
else
    msg_2 "QUICK_DEPLOY - skipping additional user:"
fi

msg_1 "^^^  setup_common_env.sh done  ^^^"
echo
