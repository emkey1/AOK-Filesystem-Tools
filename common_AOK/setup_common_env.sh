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

    echo "This is an iSH node, running $(distro_name_get)" >/etc/issue

    if [ -n "$USER_NAME" ]; then
        echo "Default user is: $USER_NAME" >>/etc/issue
    fi
    echo >>/etc/issue

    if ! command -v sudo >/dev/null; then
        error_msg "sudo not installed, common_AOK/setup_environment() can not complete"
    fi

    if ! command -v bash >/dev/null; then
        error_msg "bash not installed, common_AOK/setup_environment() can not complete"
    fi

    copy_local_bins common_AOK

    if [ ! -L /bin/login ]; then
        ls -l /bin/login
        error_msg "At this point /bin/login should be a softlink!"
    fi

    #
    #  Need full path to handle that this path is not correctly cached at
    #  this point if Debian is being installed, probably due to switching
    #  from Alpine to Debian without having rebooted yet.
    #
    msg_2 "Setitng time zone"
    if [ -n "$AOK_TIMEZONE" ]; then
        msg_3 "Using hardcoded TZ: $AOK_TIMEZONE"
        ln -sf "/usr/share/zoneinfo/$AOK_TIMEZONE" /etc/localtime
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

    if ! is_debian; then
        msg_3 "Alpine - root shell -> /bin/ash"
        sed -i "s|^root:[^:]*:|root:/bin/bash:|" /etc/passwd
    fi

    #
    #  root user env
    #
    copy_skel_files /root
    msg_3 "Add /usr/local/sbin & bin to PATH"
    echo "PATH=/usr/local/sbin:/usr/local/bin:$PATH" >>/root/.bash_profile
    chown -R root: /root
    msg_3 "clear root history"
    rm /root/.bash_history -f
}

create_user() {
    msg_2 "Creating default user and group: $USER_NAME"
    if [ -z "$USER_NAME" ]; then
        msg_3 "No user requested"
        return
    fi

    cu_home_dir="/home/$USER_NAME"
    groupadd -g 501 "$USER_NAME"

    if is_debian && [ "$USER_SHELL" = "/bin/ash" ]; then
        msg_3 "WARNING /bin/ash not available in Debian/Devuan, replacing with /bin/bash"
        USER_SHELL="/bin/bash"
    fi

    #
    #  Determine what shell to use for custom user
    #
    if [ -n "$USER_SHELL" ]; then
        if [ ! -x "${build_root_d}$USER_SHELL" ]; then
            error_msg "User shell not found: ${build_root_d} $USER_SHELL"
        fi
        use_shell="$USER_SHELL"
        msg_3 "User shell: $use_shell"
    else
        use_shell="/bin/bash"
        msg_3 "User shell (default): $use_shell"
    fi

    # temp changing UID_MIN is to silence the warning:
    # ish's uid 501 outside of the UID_MIN 1000 and UID_MAX 6000 range.
    #  add additional groups with -G
    useradd -m -s "$use_shell" -u 501 -g 501 -G sudo,root,adm "$USER_NAME" --key UID_MIN=501

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

#===============================================================
#
#   Main
#
#===============================================================

msg_script_title "setup_common_env.sh  Common AOK setup steps"

setup_environment
user_root
if [ "$QUICK_DEPLOY" -eq 0 ]; then
    # [ -n "$USER_NAME" ] &&
    create_user
else
    msg_2 "QUICK_DEPLOY - skipping additional user:"
fi

msg_1 "^^^  setup_common_env.sh done  ^^^"
