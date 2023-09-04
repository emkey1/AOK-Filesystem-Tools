#!/bin/sh
# this is sourced, shebang just to hint editors since no extension
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  setup_final_tasks.sh
#
#  Completes the setup of Alpine or Debian.
#  On normal installs, this runs at the end of the install.
#  On pre-builds this will be run on first boot at destination device,
#  so it can be assumed this is running on deploy destination
#

install_aok_apks() {
    if ! this_is_aok_kernel; then
        msg_1 "Skipping AOK only packages on non AOK kernel"
        return
    elif [ -z "$AOK_APKS" ]; then
        msg_1 "No AOK_APKS defined"
        return
    fi

    msg_1 "Install packages only for AOK kernel"

    # In this case we want the variable to expand into its components
    # shellcheck disable=SC2086
    apk add $AOK_APKS
    echo
}

replace_home_dirs() {
    if [ -n "$HOME_DIR_USER" ]; then
        if [ -f "$HOME_DIR_USER" ]; then
            [ -z "$USER_NAME" ] && error_msg "USER_HOME_DIR defined, but not USER_NAME"
            msg_2 "Replacing /home/$USER_NAME"
            cd "/home" || error_msg "Failed cd /home"
            rm -rf "$USER_NAME"
            tar xfz "$HOME_DIR_USER" || error_msg "Failed to extract USER_HOME_DIR"
	else
	    error_msg "USER_HOME_DIR file not found: $HOME_DIR_USER" "no_exit"
	fi
    fi

    if [ -n "$HOME_DIR_ROOT" ]; then
        if [ -f "$HOME_DIR_ROOT" ]; then
            msg_2 "Replacing /root"
            mv /root /root.ORIG
            cd / || error_msg "Failed to cd into: /"
            tar xfz "$HOME_DIR_ROOT" || error_msg "Failed to extract USER_HOME_DIR"
	else
	    error_msg "ROOT_HOME_DIR file not found: $HOME_DIR_ROOT" "no_exit"
	fi
    fi
}

set_initial_login_mode() {
    if [ -n "$INITIAL_LOGIN_MODE" ]; then
        #
        #  Now that final_tasks have run as root, the desired login method
        #  can be set.
        #
        msg_2 "Using defined login method. It will be used next time App is run"
        /usr/local/bin/aok -l "$INITIAL_LOGIN_MODE"
    else
        msg_2 "No login mode defined, disabling console login"
        /usr/local/bin/aok -l disable
    fi
}

start_cron_if_active() {
    msg_2 "start_cron_if_active()"
    #  shellcheck disable=SC2154
    [ "$USE_CRON_SERVICE" != "Y" ] && return

    if this_fs_is_chrooted || ! this_is_ish; then
	msg_3 "Cant attempt to start cron on a chrooted/non-iSH device"
	return
    fi

    cron_service="/etc/init.d"
    if hostfs_is_alpine; then
	cron_service="$cron_service/dcron"
    elif hostfs_is_debian; then
	cron_service="$cron_service/cron"
    else
	error_msg "cron service not available for this FS"
    fi

    openrc_might_trigger_errors
    [ ! -x "$cron_service" ] && error_msg "Cron service not found: $cron_service"
    if ! "$cron_service" status > /dev/null; then
	msg_3 "Starting cron service"
	"$cron_service" start
    fi
    msg_3 "start_cron_if_active() - done"
}

run_additional_tasks_if_found() {
    msg_2 "run_additional_tasks_if_found()"

    if [ -n "$FIRST_BOOT_ADDITIONAL_TASKS" ]; then
        msg_1 "Running additional setup tasks"
	echo "---------------"
	echo "$FIRST_BOOT_ADDITIONAL_TASKS"
	echo "---------------"
	/bin/sh -c "$FIRST_BOOT_ADDITIONAL_TASKS"
    fi
    msg_3 "run_additional_tasks_if_found()  done"
}

deploy_state_clear() {
    msg_2 "deploy_state_clear()"

    rm "$f_deploy_state"

    msg_3 "deploy_state_clear() - done"
}


#===============================================================
#
#   Main
#
#===============================================================

tsaft_start="$(date +%s)"

. /opt/AOK/tools/utils.sh
. /opt/AOK/tools/user_interactions.sh

if [ -n "$LOG_FILE" ]; then
    debug_sleep "Since log file is defined, will pause before starting" 2
fi

deploy_state_set "$deploy_state_finalizing"

msg_script_title "setup_final_tasks.sh - Final part of setup"

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

user_interactions

hostfs_is_alpine && install_aok_apks

#
#  Removing default host
#
hostn_service=/etc/init.d/hostname
if [ -f "$hostn_service" ]; then
    msg_2 "Disabling hostname service not working on iSH"
    mv -f "$hostn_service" /etc/init.d/NOT-hostname
fi

if hostfs_is_debian || hostfs_is_devuan; then
    msg_3 "Removing hostname service files not meaningfull on iSH"
    rm -f /etc/init.d/hostname
    rm -f /etc/init.d/hostname.sh
    rm -f /etc/rcS.d/S01hostname.sh
    rm -f /etc/systemd/system/hostname.service
fi

"$aok_content"/common_AOK/aok_hostname/set_aok_hostname.sh

set_initial_login_mode

if hostfs_is_alpine; then
    next_etc_profile="$aok_content/Alpine/etc/profile"
elif hostfs_is_debian; then
    next_etc_profile="$aok_content/Debian/etc/profile"
elif hostfs_is_devuan; then
    next_etc_profile="$aok_content/Devuan/etc/profile"
else
    error_msg "Undefined Distro, cant set next_etc_profile"
fi

set_new_etc_profile "$next_etc_profile"

start_cron_if_active

#
#  Handling custom files
#
"$aok_content"/common_AOK/custom/custom_files.sh

/usr/local/sbin/ensure_hostname_in_host_file.sh

replace_home_dirs


run_additional_tasks_if_found

duration="$(($(date +%s) - tsaft_start))"
display_time_elapsed "$duration" "Setup Final tasks"

deploy_state_clear

msg_1 "This system has completed the last deploy steps and is ready!"
echo
cd || error_msg "Failed to cd home"
