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
#  Completes the setup of AOK-FS
#  On normal installs, this runs at the end of the install.
#  On pre-builds this will be run on first boot at destination device,
#  so it can be assumed this is running on deploy destination
#

#
#  If aok_launcher is used as Launch Cmd, it has already waited for
#  system to be ready, so can be skipped here
#
wait_for_bootup() {
    # msg_2 "wait_for_bootup()"
    if [ "$(get_kernel_default launch_command)" != "$launch_cmd_AOK" ]; then
        if deploy_state_is_it "$deploy_state_pre_build" &&
            ! hostfs_is_devuan &&
            ! this_fs_is_chrooted; then
            msg_2 "Waiting for runlevel default to be ready, normally < 10s"
            msg_3 "iSH sometimes fails this, so if this doesnt move on, try restarting iSH"
            while ! rc-status -r | grep -q default; do
                msg_3 "not ready"
                sleep 2
            done
        fi
    else
        msg_2 "Boot wait already handled by AOK Launch cmd"
    fi
    # msg_3 "wait_for_bootup() - done"
}

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
    msg_2 "Ensure path items pottentially on iCloud are available"

    # shellcheck disable=SC2154
    items_to_check="\
        $HOME_DIR_USER \
        $HOME_DIR_ROOT \
        $POPULATE_FS \
        $FIRST_BOOT_ADDITIONAL_TASKS \
        $ALT_HOSTNAME_SOURCE_FILE \
        $CUSTOM_FILES_TEMPLATE"

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

aok_kernel_consideration() {
    msg_2 "aok_kernel_consideration()"
    if ! this_is_aok_kernel || this_fs_is_chrooted; then
        msg_3 "Not direct aok kernel!"
        #min_release 3.18 || {
        #    msg_3 "procps wont work on regular iSH for Alpine < 3.18"
        #    apk del procps || {
        #        error_msg "apk del procps failed"
        #    }
        #}
        return
    fi

    [ -n "$AOK_APKS" ] && {
        msg_3 "Install packages only for AOK kernel: $AOK_APKS"
        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086 # in this case variable should expand
        apk add $AOK_APKS || {
            error_msg "apk add AOK_APKS failed"
        }
    }

    deploy_bat_monitord
}

start_cron_if_active() {
    msg_2 "start_cron_if_active()"
    #  shellcheck disable=SC2154
    [ "$USE_CRON_SERVICE" != "Y" ] && return

    ensure_ish_or_chrooted "Cant attempt to start cron on a chrooted/non-iSH device"

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

deploy_bat_monitord() {
    s_name="bat-monitord"

    msg_2 "Battery monitor service $s_name"

    this_is_aok_kernel || {
        msg_3 "$s_name is only meaningfull on iSH-AOK, skipping"
        return
    }

    msg_3 "Adding $s_name service"
    cp -a /opt/AOK/common_AOK/etc/init.d/bat-monitord /etc/init.d
    rc-update add "$s_name" default
    msg_3 "Not starting it during deploy, it will start on next boot"
    #rc-service "$s_name" restart

    msg_2 "service $s_name installed and enabled"
    echo
}

run_additional_tasks_if_found() {
    msg_2 "run_additional_tasks_if_found()"

    [ -n "$FIRST_BOOT_ADDITIONAL_TASKS" ] && {
        msg_1 "Running additional final setup tasks"
        echo "---------------"
        echo "$FIRST_BOOT_ADDITIONAL_TASKS"
        echo "---------------"
        /bin/sh -c "$FIRST_BOOT_ADDITIONAL_TASKS" || {
            error_msg "FIRST_BOOT_ADDITIONAL_TASKS returned error"
        }
        msg_1 "Returned from the additional setup tasks"
    }
    # msg_3 "run_additional_tasks_if_found()  done"
}

clean_up_dest_env() {
    msg_2 "clear deploy state"
    rm "$f_dest_fs_deploy_state"

    rm -f "$f_home_user_replaced"
    rm -f "$f_home_root_replaced"
    rm -f "$f_hostname_initial"

    # dont remove if final dest is chrooted!
    if this_fs_is_chrooted; then
        msg_3 "dest is chrooted - Leaving: $f_chroot_hostname"
    else
        rm -f "$f_chroot_hostname"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

prog_name_sft=$(basename "$0")
tsaft_start="$(date +%s)"
echo
echo "=_=_="
echo "=====   $prog_name_sft started $(date)   ====="
echo "=_=_="
echo

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# shellcheck source=/opt/AOK/tools/utils.sh
[ -z "$d_aok_etc" ] && . /opt/AOK/tools/utils.sh
. /opt/AOK/tools/ios_version.sh
. /opt/AOK/tools/user_interactions.sh

this_is_aok_kernel && hostfs_is_alpine && min_release "3.20" && {
    echo
    echo "On iSH-AOK rsync and other core bins will fail in Alpine 3.20"
    error_msg "For now using Alpine 3.19 or older is recomended"
}

deploy_state_set "$deploy_state_finalizing"
msg_script_title "$prog_name_sft - Final part of setup"

msg_2 "Dest platform aok tweaks"
if this_fs_is_chrooted; then
    aok -s off # should happen before set_hostname
else
    this_is_aok_kernel || {
        msg_3 "Not ish-aok kernel, disabling suffix"
        aok -s off
    }
    aok -C off -l aok
fi

user_interactions # mount iCloud & set TZ
ensure_path_items_are_available
set_hostname # it might have changed since pre-build...

hostfs_name="$(hostfs_detect)"
f_fs_final_tasks=/opt/AOK/"$hostfs_name"/setup_final_tasks.sh
[ -f "$f_fs_final_tasks" ] && {
    msg_1 "Running $hostfs_name final tasks"
    "$f_fs_final_tasks" || error_msg "$f_fs_final_tasks failed"
    msg_2 "$hostfs_name final tasks - done"
    echo
}

this_is_ish && wait_for_bootup

#
#  Setting up chroot env to use aok_launcher
#
if this_fs_is_chrooted; then
    _f="/usr/local/sbin/aok_launcher"
    msg_2 "Preparing chroot environment"
    msg_3 "Setting default chroot app: $_f"
    echo "$_f" >/.chroot_default_cmd
    [ -z "$USER_NAME" ] && aok -a "root"
fi

[ -n "$USER_NAME" ] && {
    msg_3 "Enabling Autologin for $USER_NAME"
    aok -a "$USER_NAME"
}

if test -f /AOK; then
    msg_1 "Removing obsoleted /AOK new location is /opt/AOK"
    rm -rf /AOK
fi

#
#  Currently Debian doesnt seem to have to take the iSH app into
#  consideration
#
hostfs_is_alpine && aok_kernel_consideration

if hostfs_is_alpine; then
    next_etc_profile="/opt/AOK/Alpine/etc/profile"
elif hostfs_is_debian || hostfs_is_devuan; then
    next_etc_profile="/opt/AOK/FamDeb/etc/profile"
else
    error_msg "Undefined Distro, cant set next_etc_profile"
fi

set_new_etc_profile "$next_etc_profile"

# to many issues - not worth it will start after reboot anyhow
# start_cron_if_active

#
#  Handling custom files
#
/opt/AOK/common_AOK/custom/custom_files.sh || {
    error_msg "common_AOK/custom/custom_files.sh failed"
}

replace_home_dirs
run_additional_tasks_if_found

duration="$(($(date +%s) - tsaft_start))"
display_time_elapsed "$duration" "Setup Final tasks"

clean_up_dest_env

/usr/local/bin/check-env-compatible

msg_1 "File system deploy completed"

/usr/local/bin/aok-versions

echo
echo "Setup has completed the last deploy steps and is ready!
You are recomended to reboot in order to ensure that all services are started,
and your environment is used."
