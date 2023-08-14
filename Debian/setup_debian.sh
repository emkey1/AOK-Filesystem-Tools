#!/bin/sh
#  shellcheck disable=SC2154

#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  setup_debian.sh
#
#  This modifies a Debian Linux FS with the AOK changes
#

prepare_env_etc() {
    msg_2 "prepare_env_etc() - Replacing a few /etc files"

    msg_3 "Debian AOK inittab"
    cp -a "$aok_content"/Debian/etc/inittab /etc

    #
    #  Most of the Debian services, mounting fs, setting up networking etc
    #  serve no purpose in iSH, since all this is either handled by iOS
    #  or done by the app before bootup
    #
    msg_3 "Disabling previous openrc runlevel tasks"
    rm /etc/runlevels/*/* -f

    msg_3 "Adding env versions & AOK Logo to /etc/update-motd.d"
    mkdir -p /etc/update-motd.d
    cp -a "$aok_content"/Debian/etc/update-motd.d/* /etc/update-motd.d

    msg_3 "prepare_env_etc() done"
}

debian_services() {
    #
    #  Setting up suitable services, and removing those not meaningfull
    #  on iSH
    #
    msg_2 "debian_services()"
    msg_3 "Remove previous ssh host keys if present"
    rm -f /etc/ssh/ssh_host*key*

    msg_2 "Add services for runlevel boot"
    rc-update add urandom boot

    msg_3 "Add services for runlevel off"
    rc-update add sendsigs off
    rc-update add umountroot off
    rc-update add urandom off

    msg_3 "Disable some auto-enabled services that wont make sense in iSH"
    openrc_might_trigger_errors

    rc-update del dbus default
    rc-update del elogind default
    rc-update del rsync default
    rc-update del sudo default
}

setup_login() {
    #
    #  What login method will be used is setup during FIRST_BOOT,
    #  at this point we just ensure everything is available and initial boot
    #  will use the default loging that should work on all platforms.
    #
    # SKIP_LOGIN
    msg_2 "Install Debian AOK login methods"
    cp "$aok_content"/Debian/bin/login.loop /bin
    chmod +x /bin/login.loop
    cp "$aok_content"/Debian/bin/login.once /bin
    chmod +x /bin/login.once

    cp -a "$aok_content"/Debian/etc/pam.d/common-auth /etc/pam.d

    mv /bin/login /bin/login.original

    # ln -sf /bin/login.original /bin/login

    #
    #  In order to ensure 1st boot will be able to run, for now
    #  disable login. If INITIAL_LOGIN_MODE was set, the selected
    #  method will be activated at the end of the setup
    #
    /usr/local/bin/aok -l disable >/dev/null || {
        error_msg "Failed to disable login during deploy"
    }

    if [ ! -L /bin/login ]; then
        ls -l /bin/login
        error_msg "At this point /bin/login should be a softlink!"
    fi
}

mimalloc_install() {
    msg_2 "mimalloc_install()"
    apt -y install cmake gcc-8-multilib
    cd /tmp || error_msg "mimalloc_install() Failed: cd /tmp"
    git clone https://github.com/xloem/mimalloc
    cd mimalloc || error_msg "mimalloc_install() Failed: cd mimalloc"
    git checkout vmem
    mkdir build
    cd build || error_msg "mimalloc_install() Failed: cd build"
    cmake ..
    make install
    cp -av "$aok_content"/Debian/mimalloc_patch/mimalloc /usr/local/bin
    msg_3 "mimalloc_install() - done"
}

#===============================================================
#
#   Main
#
#===============================================================

tsd_start="$(date +%s)"

#
#  Ensure important devices are present.
#  this is not yet in inittab, so run it from here on 1st boot
#
echo "-->  Running fix_dev  <--"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev ignore_init_check
echo

#  shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

deploy_starting

if [ "$build_env" -eq 0 ]; then
    echo
    echo "##  WARNING! this setup only works reliably on iOS/iPadOS and Linux(x86)"
    echo "##           You have been warned"
    echo
fi

msg_script_title "setup_debian.sh  Debian specific AOK env"

msg_3 "Create /var/log/wtmp"
touch /var/log/wtmp

initiate_deploy Debian "$(cat /etc/debian_version)"

prepare_env_etc

msg_1 "apt update"
apt update -y

if [ "$QUICK_DEPLOY" -eq 0 ] || [ "$QUICK_DEPLOY" -eq 2 ]; then
    msg_1 "apt upgrade"
    apt upgrade -y

    if [ -n "$DEB_PKGS" ]; then
        msg_1 "Add Debian packages"
        echo "$DEB_PKGS"
        bash -c "DEBIAN_FRONTEND=noninteractive apt install -y $DEB_PKGS"
    fi
    echo
else
    msg_1 "QUICK_DEPLOY - skipping apt upgrade and DEB_PKGS"
fi

#
#  Common deploy, used both for Alpine & Debian
#
if ! "$setup_common_aok"; then
    error_msg "$setup_common_aok reported error"
fi

setup_login

debian_services

#
#  Overriding common runbg with Debian specific, work in progress...
#
# msg_2 "Adding runbg service"
# cp -a "$aok_content"/Devuan/etc/init.d/runbg /etc/init.d
# ln -sf /etc/init.d/runbg /etc/rc2.d/S04runbg

if [ "$USE_MIMALLOC" = "YES" ]; then
    mimalloc_install
else
    msg_2 "Skipping MIMALLOC patch"
fi

#
#  Depending on if prebuilt or not, either setup final tasks to run
#  on first boot or now.
#
if deploy_state_is_it "$deploy_state_pre_build"; then
    set_new_etc_profile "$setup_final"
else
    "$setup_final"
    not_prebuilt=1
fi

msg_1 "Setup complete!"

duration="$(($(date +%s) - tsd_start))"
display_time_elapsed "$duration" "Setup Debian"

if [ "$not_prebuilt" = 1 ]; then
    msg_1 "Please reboot/restart this app now!"
    echo "/etc/inittab was changed during the install."
    echo "In order for this new version to be used, a restart is needed."
    echo
fi
