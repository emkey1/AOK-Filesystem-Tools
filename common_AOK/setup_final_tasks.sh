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

ensure_path_items_are_available() {
    #
    #  If this is run on an iOS device with limited storage, config
    #  items located on iCloud mounts might not be synced.
    #  Simplest thing is to look through config items that might contain
    #  files or directories, and ensuring those items are present.
    #  Any further specific sync are better done in
    #  FIRST_BOOT_ADDITIONAL_TASKS, where precise knowledge of that
    #  device should make specific requirements self explanatory.
    #
    msg_2 "ensure_path_items_are_available()"

    # shellcheck disable=SC2154
    items_to_check="\
        $HOME_DIR_USER \
        $HOME_DIR_ROOT \
        $POPULATE_FS \
        $FIRST_BOOT_ADDITIONAL_TASKS \
        $ALT_HOSTNAME_SOURCE_FILE \
        $ALPINE_CUSTOM_FILES_TEMPLATE \
        $DEBIAN_CUSTOM_FILES_TEMPLATE"

    while true; do
        one_item="${items_to_check%% *}"
        items_to_check="${items_to_check#* }"
        if [ -e "$one_item" ]; then
            msg_3 "Ensuring it is synced: $one_item"
            find "$one_item" >/dev/null
        fi
        [ "$one_item" = "$items_to_check" ] && break # we have processed last item
    done

    unset items_to_check
    unset one_item
    # msg_3 "ensure_path_items_are_available() - done"
}

hostname_fix() {
    #
    #  workarounds for iOS 17 no longer supporting hostname detection
    #

    if [ -n "$ALT_HOSTNAME_SOURCE_FILE" ]; then
        msg_2 "Hostname workaround is requesed by setting ALT_HOSTNAME_SOURCE_FILE"
    elif [ "$(ios_matching 17.0)" = "Yes" ]; then
        msg_2 "iOS >= 17, hostname workaround will be used"
    elif [ "$(/bin/hostname)" = "localhost" ]; then
        #
        #  If hostname is localhost, assume this runs on iOS >= 17
        #  In the utterly rare case ths user has named his iOS device
        #  localhost, this would be an incorrect assumption
        #
        msg_2 "Will assume this runs on iOS >= 17, hostname workaround will be used"
    else
        msg_2 "Will assume this runs on iOS < 17, so hostname can be set by the app"
        return
    fi

    # if defined use setting from AOK_VARS, otherwise a prompt will be given
    /usr/local/bin/aok -H enable "$ALT_HOSTNAME_SOURCE_FILE"
}

aok_kernel_consideration() {
    msg_2 "aok_kernel_consideration()"
    if ! this_is_aok_kernel; then
        if ! min_release 3.18; then
            msg_3 "procps wont work on regular iSH for Alpine < 3.18"
            apk del procps || {
                error_msg "apk del procps failed"
            }
        fi
    elif [ -n "$AOK_APKS" ]; then
        msg_3 "Install packages only for AOK kernel"
        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086
        apk add $AOK_APKS || {
            error_msg "apk add AOK_APKS failed"
        }
    fi
    # msg_3 "aok_kernel_consideration() - done"
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

verify_alpine_uptime() {
    #
    #  Some versions of uptime doesnt work in iSH, test and
    #  replace with softlink to busybox if that is the case
    #
    uptime_cmd="$(command -v uptime)"
    uptime_cmd_real="$(realpath "$uptime_cmd")"
    if [ "$uptime_cmd_real" = "/bin/busybox" ]; then
        #
        #  Already using busybox, nothing needs to be done
        #
        return
    fi
    "$uptime_cmd" >/dev/null || {
        msg_2 "WARNING: Installed uptime not useable!"
        msg_3 "changing it to busybox symbolic link"
        rm -f "$uptime_cmd"
        ln -sf /bin/busybox "$uptime_cmd"
    }
}

start_cron_if_active() {
    msg_2 "start_cron_if_active()"
    #  shellcheck disable=SC2154
    [ "$USE_CRON_SERVICE" != "Y" ] && return

    if this_fs_is_chrooted || ! this_is_ish; then
        error_msg "Cant attempt to start cron on a chrooted/non-iSH device"
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
    if ! "$cron_service" status >/dev/null; then
        msg_3 "Starting cron service"
        "$cron_service" start
    fi
    # msg_3 "start_cron_if_active() - done"
}

set_launch_cmd() {
    msg_2 "Setting 'Launch cmd' to run /usr/local/sbin/dynamic_login"

    launch_cmd_expected='[ "/usr/local/sbin/dynamic_login" ]'
    f_launch_cmd="/proc/ish/defaults/launch_command"

    this_is_ish || {
        msg_3 "Can only set 'Launch cmd' on iSH nodes!"
        return
    }

    msg_3 "Setting default user as root, and enabeling continous logins"
    echo "root" >"$f_login_default_user"
    touch "$f_logins_continous"

    msg_3 "Setting the custom AOK-FS 'Launch cmd'"
    echo "$launch_cmd_expected" >"$f_launch_cmd"
    launch_cmd_current="$(tr -d '\n' <"$f_launch_cmd" | sed 's/  \+/ /g' | sed 's/"]/" ]/')"

    if [ "$launch_cmd_current" != "$launch_cmd_expected" ]; then
        msg_1 "Failed to set 'Launch cmd'!"
        echo "Current 'Launch cmd': '$launch_cmd_current'"
        echo
        echo "To set the default, run this:"
        echo
        echo "sudo echo '$launch_cmd_expected' > $f_launch_cmd"
        echo
    fi
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

run_additional_tasks_if_found() {
    msg_2 "run_additional_tasks_if_found()"

    if [ -n "$FIRST_BOOT_ADDITIONAL_TASKS" ]; then
        msg_1 "Running additional setup tasks"
        echo "---------------"
        echo "$FIRST_BOOT_ADDITIONAL_TASKS"
        echo "---------------"
        /bin/sh -c "$FIRST_BOOT_ADDITIONAL_TASKS" || {
            error_msg "FIRST_BOOT_ADDITIONAL_TASKS returned error"
        }
    fi
    # msg_3 "run_additional_tasks_if_found()  done"
}

deploy_state_clear() {
    msg_2 "deploy_state_clear()"

    rm "$f_dest_fs_deploy_state"

    # msg_3 "deploy_state_clear() - done"
}

#===============================================================
#
#   Main
#
#===============================================================

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

tsaft_start="$(date +%s)"

. /opt/AOK/tools/utils.sh
. /opt/AOK/tools/ios_version.sh
. /opt/AOK/tools/user_interactions.sh

#
#  Wait for bootup to complete if prebuild and not chrooted on iSH
#
if deploy_state_is_it "$deploy_state_pre_build" &&
    this_is_ish &&
    ! hostfs_is_devuan &&
    ! this_fs_is_chrooted; then
    msg_2 "Waiting for runlevel default to be ready, normally < 10s"
    msg_3 "iSH sometimes fails this, so if this doesnt move on, try restarting iSH"
    while ! rc-status -r | grep -q default; do
        msg_3 "not ready"
        sleep 2
    done
fi

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

ensure_path_items_are_available

hostname_fix

#
#  Currently Debian doesnt seem to have to take the iSH app into
#  consideration
#
hostfs_is_alpine && aok_kernel_consideration

"$d_aok_base"/common_AOK/hostname_handling/set_aok_hostname.sh || {
    error_msg "set_aok_hostname.sh failed" no_exit
}

# login feature didsabled tag
# set_initial_login_mode

if hostfs_is_alpine; then
    next_etc_profile="$d_aok_base/Alpine/etc/profile"
    #
    #  Some versions of Alpine uptime doesnt work in ish, test and
    #  replace with softlink to busybox if that is the case
    #
    verify_alpine_uptime
elif hostfs_is_debian; then
    next_etc_profile="$d_aok_base/Debian/etc/profile"
elif hostfs_is_devuan; then
    next_etc_profile="$d_aok_base/Devuan/etc/profile"
else
    error_msg "Undefined Distro, cant set next_etc_profile"
fi

set_new_etc_profile "$next_etc_profile"

# to many issues - not worth it will start after reboot anyhow
# start_cron_if_active

set_launch_cmd

#
#  Handling custom files
#
"$d_aok_base"/common_AOK/custom/custom_files.sh || {
    error_msg "ERROR: common_AOK/custom/custom_files.sh failed"
}

/usr/local/sbin/ensure_hostname_in_host_file.sh || {
    error_msg "ERROR: /usr/local/sbin/ensure_hostname_in_host_file.sh failed!"
}

replace_home_dirs

run_additional_tasks_if_found

duration="$(($(date +%s) - tsaft_start))"
display_time_elapsed "$duration" "Setup Final tasks"

deploy_state_clear

msg_1 "File system deploy completed"

display_installed_versions

echo "Setup has completed the last deploy steps and is ready!"
echo "You are recomended to reboot in order to ensure that your environment is used."
echo

cd || error_msg "Failed to cd home"
