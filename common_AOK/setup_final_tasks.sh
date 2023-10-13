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

sync_dir() {
    #
    #  In case this is an iCloud location, give iCloud a nudge to sync it
    #  to minimize risk that the file hasnt been synced yet
    #

    # msg_2 "sync_dir()"
    [ -z "$1" ] && return

    # extract dir path of $1 param
    if [ -d "$1" ]; then
        dir_name="$1"
    else
        dir_name="$(dirname "$1")" # probably was file
    fi

    [ ! -d "$dir_name" ] && return # dir not found

    #
    #  Abort in case dir is obviously not an icloud mount and/or would take
    #  a considerable time to process with find
    #
    case "$dir_name" in
    "." | "/" | "/usr") return ;;
    *) ;;
    esac

    #
    #  Since we verified that dir_name exists, the only normal reason
    #  to get an error from find is if a file needed to be synced by
    #  iCloud and thus gave an error indication
    #
    find "$dir_name" >/dev/null 2>&1 || {
        msg_2 "sync_dir $dir_name - Location was synced!"
    }
    # msg_3 "sync_dir() - done"
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

replace_home_dirs() {
    if [ -n "$HOME_DIR_USER" ]; then
        sync_dir "$HOME_DIR_USER"
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
        sync_dir "$HOME_DIR_ROOT"
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
    msg_3 "run_additional_tasks_if_found()  done"
}

deploy_state_clear() {
    msg_2 "deploy_state_clear()"

    rm "$f_dest_fs_deploy_state"

    # msg_3 "deploy_state_clear() - done"
}

hostname_fix() {
    #
    #  workarounds for iOS 17 no longer supporting hostname detection
    #  in iSH, if ios version cant be detected, default to
    #  USE_SYNC_FILE_HOSTNAME
    #  should be Y if default is to use the feature
    #
    case "$(ios_matching 17.0 "$USE_SYNC_FILE_HOSTNAME")" in

    "Yes" | "Y" | "y")
        msg_3 "Will assume this runs on iOS >= 17, hostname workaround will be used"
        ;;

    *)
        msg_3 "Will assume this runs on iOS < 17, so hostname can be set by the app"
        return
        ;;

    esac

    #  shellcheck disable=SC2154
    if [ -f "$HOSTNAME_SYNC_FILE" ]; then
        echo "$HOSTNAME_SYNC_FILE" >/etc/opt/hostname_sync_fname
    fi
    /usr/local/bin/aok -H enable

    #
    #  Hostname should be set now
    #
    msg_3 "custom hostname $(/usr/local/bin/hostname)"
    regular_hostname="$(/bin/hostname)"
    msg_3 "regular hostname: [$regular_hostname]"
    cat /etc/hostname
    msg_3 "above is /etc/hostname content"

    if this_is_aok_kernel; then
        [ "$regular_hostname" = "localhost" ] && error_msg "ABORT should not be localhost on iSH-AOK"
        msg_3 "verifying ish-aok /bin/hostname doesnt report localhost"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

tsaft_start="$(date +%s)"

#  Ensure usr local bin is first in path, so our custom stuff is picked up
export PATH="/usr/local/bin:$PATH"

. /opt/AOK/tools/utils.sh
. /opt/AOK/tools/vers_checks.sh
. /opt/AOK/tools/user_interactions.sh

#
#  Only run if prebuild and not chrooted on iSH
#
if deploy_state_is_it "$deploy_state_pre_build" &&
    this_is_ish &&
    ! hostfs_is_devuan &&
    ! this_fs_is_chrooted; then
    msg_2 "Waiting for runlevel default to be ready, normally < 10s"
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

hostname_fix

user_interactions

#
#  Currently Debian doesnt seem to have to take the iSH app into
#  consideration
#
hostfs_is_alpine && aok_kernel_consideration

"$aok_content"/common_AOK/custom_hostname/set_aok_hostname.sh || {
    echo "ERROR: set_aok_hostname.sh failed"
    return
}

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

# to many issues - not worth it will start after reboot anyhow
# start_cron_if_active

#
#  Handling custom files
#
"$aok_content"/common_AOK/custom/custom_files.sh || {
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

msg_1 "This system has completed the last deploy steps and is ready!"
echo "You are recomended to reboot in order to ensure that your environment is used."
echo

cd || error_msg "Failed to cd home"
