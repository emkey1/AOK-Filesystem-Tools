#!/usr/bin/env bash
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Runs shellcheck on all included scripts
#

prog_name=$(basename "$0")

echo "$prog_name"
echo

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else.
#
cd /opt/AOK || {
    error_msg "Failed to cd into: /opt/AOK"
}

checkables=(
    tools/do_chroot.sh
    tools/shellchecker.sh # obviously self-check :)
    tools/utils.sh

    # Alpine/cron/15min/dmesg_save
    Alpine/etc/profile
    Alpine/usr_local_bin/aok
    Alpine/usr_local_bin/aok_groups
    Alpine/usr_local_bin/apt
    Alpine/usr_local_bin/disable_vnc
    Alpine/usr_local_bin/do_fix_services
    Alpine/usr_local_bin/enable_vnc
    # Alpine/usr_local_bin/idev_ip  binary
    Alpine/usr_local_bin/update
    Alpine/usr_local_bin/vnc_start
    Alpine/usr_local_bin/what_owns
    Alpine/usr_local_sbin/update_motd
    Alpine/setup_alpine_final_tasks.sh
    Alpine/setup_alpine.sh

    \
    choose_distro/install_debian.sh
    choose_distro/select_distro_prepare.sh
    choose_distro/select_distro.sh

    ## common_AOK/etc/skel/.bash_profile
    common_AOK/usr_local_bin/disable_sshd
    # common_AOK/usr_local_bin/dmesg  perl
    common_AOK/usr_local_bin/elock
    common_AOK/usr_local_bin/enable_sshd
    # common_AOK/usr_local_bin/finger  perl
    common_AOK/usr_local_bin/fix_services
    common_AOK/usr_local_bin/iCloud
    common_AOK/usr_local_bin/installed
    common_AOK/usr_local_bin/ipad_tmux
    common_AOK/usr_local_bin/iphone_tmux
    common_AOK/usr_local_bin/myip
    common_AOK/usr_local_bin/pbcopy
    common_AOK/usr_local_bin/set-timezone
    common_AOK/usr_local_bin/showip
    common_AOK/usr_local_bin/toggle_multicore
    common_AOK/usr_local_bin/version
    common_AOK/usr_local_sbin/ensure_hostname_in_host_file.sh
    common_AOK/usr_local_sbin/fix_dev
    common_AOK/setup_common_env.sh

    # Weird, if this is used, I get shellcheck issues listed in /etc/bash.bashrc
    # Debian/etc/profile
    Debian/etc/update-motd.d/11-aok-a-deb-vers
    Debian/etc/update-motd.d/11-aok-b-aok-release
    Debian/etc/update-motd.d/11-aok-c-ish-release
    Debian/etc/update-motd.d/11-aok-d-aok-logo
    Debian/usr_local_sbin/reset-run-dir.sh
    Debian/setup_debian.sh

    Devuan/etc/update-motd.d/11-aok-a-deb-vers
    Devuan/etc/update-motd.d/11-aok-b-aok-release
    Devuan/etc/update-motd.d/11-aok-c-ish-release
    Devuan/etc/update-motd.d/11-aok-d-aok-logo
    Devuan/setup_devuan.sh

    AOK_VARS
    build_fs
    compress_image
)

do_shellcheck="$(command -v shellcheck)"
# do_checkbashisms="$(command -v checkbashisms)"

if [[ "${do_shellcheck}" = "" ]] && [[ "${do_checkbashisms}" = "" ]]; then
    echo "ERROR: neither shellcheck nor checkbashisms found, can not proceed!"
    exit 1
fi

printf "Using: "
if [[ -n "${do_shellcheck}" ]]; then
    printf "%s " "shellcheck"
fi
if [[ -n "${do_checkbashisms}" ]]; then
    printf "%s " "checkbashisms"
    #  shellcheck disable=SC2154
    if [[ "$build_env" -eq 1 ]]; then
        if checkbashisms --version | grep -q 2.21; then
            echo
            echo "WARNING: this version of checkbashisms runs extreamly slowly on iSH!"
            echo "         close to a minute/script"
        fi
    fi
fi
printf "\n\n"

for script in "${checkables[@]}"; do
    #  abort as soon as one lists issues
    echo "Checking: ${script}"
    if [[ "${do_shellcheck}" != "" ]]; then
        shellcheck -x -a -o all -e SC2250,SC2312 "${script}" || exit 1
    fi
    if [[ "${do_checkbashisms}" != "" ]]; then
        checkbashisms -n -e -x "${script}" || exit 1
    fi
done
