#!/bin/sh
#  shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  This enhances an Alpine Linux FS with the AOK changes
#
#  On compatible platforms, Linux (x86) and iSH this can be run chrooted
#  before compressing the file system, to deliver a ready to be used file system.
#  When the FS is prepared on other platforms,
#  this file has to be run inside iSH once the file system has been mounted.
#
#  Comment strategy
#  Each section starts with: echo "---  Replacing a few key files  ---"
#  no end of section notifier, if an issue is spotted it should be within the
#  last labeled section
#
#  Comments inside a section use a prefix to make them stand out from other output:
#    echo "-> Copying /etc/profile"
#  If they should stand out a bit more prepend with an empty echo line,
#  but dont overdo it.
#
#  TODO: should vim really be a link to vi, goes against normal procedures
#

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

# Set some variables
# shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV





# Pretty sure this is no longer needed, but i leave it commented out for now
# has_been_run="/etc/opt/aok_setup_fs-done"


activate_runbg() {
    msg_1 "Activating this to run in the background"

    msg_2 "Ensuring openrc is installed"
    apk add openrc

    msg_2 "Adding runbg service"
    cp -a "$AOK_CONTENT"/Alpine/etc/init.d/runbg /etc/init.d
    if [ -n "$(echo "$(cat /etc/alpine-release)" 3.14.8 | \
         awk '{if ($1 <= $2) print $1}')" ]; then
        msg_3 "Adding some /etc/init.d files for older versions"
        cp -av "$AOK_CONTENT"/Alpine/etc/init.d/devfs /etc/init.d
        cp -av "$AOK_CONTENT"/Alpine/etc/init.d/hostname /etc/init.d
        cp -av "$AOK_CONTENT"/Alpine/etc/init.d/hwdrivers /etc/init.d
        cp -av "$AOK_CONTENT"/Alpine/etc/init.d/networking /etc/init.d
    fi

    #
    #  Not needed on all releases
    #
    case "$ALPINE_RELEASE" in

        "3.14")
            if is_aok_kernel; then
                msg_2 "Replacing /etc/rc.conf"
                cp /etc/rc.conf /etc/rc.conf.orig
                cp "$AOK_CONTENT"/Alpine/etc/rc.conf /etc
            else
                msg_2 "Not changing /etc/rc.conf when not AOK kernel"
            fi
            ;;

        *)
            # Not changing /etc/rc.conf on this Alpine release
            ;;

    esac

    mkdir /run/openrc
    touch /run/openrc/softlevel

    #
    # Older Alpines needs to run openrc-init
    #
    case "$ALPINE_RELEASE" in

        "3.12" | "3.13" | "3.14" | "3.15")
            openrc-init
            ;;

        *)
            msg_2 "Skipping openrc-init on: $ALPINE_RELEASE"
            ;;

    esac

    msg_2 "Setting runlevel to 'default'"
    openrc_might_trigger_errors
    openrc default 2> /dev/null

    msg_2 "Activating runbg"
    rc-update add runbg
    rc-service runbg start

    if ! build_status_get "$STATUS_IS_CHROOTED" ; then
        #  Only report task switching usable if this a post-boot generated
        #  file system
        echo
        echo
        msg_1 "Task switching is now supported!"
        echo
        echo
    fi
}

install_apks() {
    if [ -n "$CORE_APKS" ]; then
        msg_2 "Add initial packages"

        #  busybox-extras no longer a package starting with 3.16, so delete if present
        if [ "$(awk 'BEGIN{print ('"$ALPINE_RELEASE"' > 3.15)}')" -eq 1 ]; then
            msg_3 "Removing busybox-extras from core apks, not available past 3.15"
            CORE_APKS="$(echo "$CORE_APKS" | sed 's/busybox\-extras//')"
        fi

        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086
        apk add $CORE_APKS

        #
        #  Starting with 3.16 shadow /bin/login is in its own package
        #  simplest way to handle this is to just check if such a package
        #  is present, if found install it.
        #
        if [ -n "$(apk search shadow-login)" ]; then
            msg_3 "Installing shadow-login"
            apk add shadow-login
        fi
    fi

    if [ "$BUILD_ENV" -eq 1 ] && ! is_aok_kernel; then
        msg_2 "Skipping AOK only packages on non AOK kernels"
    elif [ -n "$AOK_APKS" ]; then
        #  Only deploy on aok kernels and if any are defined
        #  This might not be deployed on a system with the AOK kernel, but we cant
        #  know at this point in time, so play it safe and install them
        msg_2 "Add packages only for AOK kernel"
        # In this case we want the variable to expand into its components
        # shellcheck disable=SC2086
        apk add $AOK_APKS
    fi
}

replace_key_files() {
    msg_2 "Replacing a few key files"

    # Remove extra unused vty's, make OpenRC work
    cp "$AOK_CONTENT"/Alpine/etc/inittab /etc

    # Fake interfaces file
    cp "$AOK_CONTENT"/Alpine/etc/interfaces /etc/network

    ln /etc/init.d/devfs /etc/init.d/dev

    # Networking, hostname and possibly others can't start because of
    # current limitations in iSH So we fake it out
    rm /etc/init.d/networking

    # More hackery.  Initial case is the need to make pam_motd.so optional
    # So that the ish user will work in Alpine 3.14
    cp "$AOK_CONTENT"/Alpine/etc/pam.d/* /etc/pam.d
}



#===============================================================
#
#   Main
#
#===============================================================

test -f "$ADDITIONAL_TASKS_SCRIPT" && notification_additional_tasks

! is_iCloud_mounted && iCloud_mount_prompt_notification

msg_1 "Setting up iSH-AOK FS: ${AOK_VERSION} on new filesystem"

echo "$ALPINE_RELEASE" > "$FILE_ALPINE_RELEASE"

msg_2 "apk update & upgrade"
apk update
apk upgrade

! is_iCloud_mounted && should_icloud_be_mounted

#  Do this early on dest platform, ie non-chrooted, to allow task switching ASAP
build_status_get "$STATUS_IS_CHROOTED" || activate_runbg

msg_1 "Setting up AOK FS"

if [ -z "$ALPINE_RELEASE" ]; then
    error_msg "ALPINE_RELEASE param not supplied"
fi

install_apks

#  if it is a chrooted pre-build, it makes more sense to do it here, after
#  everything is already installed and upgraded
build_status_get "$STATUS_IS_CHROOTED" && activate_runbg

replace_key_files


msg_3 "adding pkg shadow & group sudo"
apk add shadow
groupadd sudo


# cron stuff
cp "$AOK_CONTENT"/Alpine/cron/15min/* /etc/periodic/15min

msg_3 "Add our Alpine stuff to /usr/local/bin"
mkdir -p /usr/local/bin
cp "$AOK_CONTENT"/Alpine/usr_local_bin/* /usr/local/bin
chmod +x /usr/local/bin/*


msg_3 "Add our stuff to /usr/local/sbin"
mkdir -p /usr/local/sbin
cp "$AOK_CONTENT"/Alpine/usr_local_sbin/* /usr/local/sbin
chmod +x /usr/local/sbin/*




#
#  Extra sanity check, only continue if there is a runable /bin/login
#
if [ ! -x /bin/login ]; then
    error_msg "CRITICAL!! no run-able /bin/login present!"
fi

# #
# #  Indicate this has been completed, to prevent future runs by mistake
# #
# touch "$has_been_run"


msg_1 "Running $SETUP_COMMON_AOK"
"$SETUP_COMMON_AOK"

msg_1 "running $SETUP_ALPINE_FINAL"
"$SETUP_ALPINE_FINAL"

select_profile "$PROFILE_ALPINE"

run_additional_tasks_if_found
