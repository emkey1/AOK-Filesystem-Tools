#!/usr/bin/env bash
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#  Version: 1.1.0 2022-06-18
#
#
#  Runs shellcheck on all included scripts
#

#  shellcheck disable=SC1007
CURRENT_D=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FS_BUILD_D="$(dirname "${CURRENT_D}")"

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else.
#
cd "${FS_BUILD_D}" || exit 1


checkables=(
    tools/shellchecker.sh      # First self-check :)
    tools/do_chroot.sh

    build_fs
    setup_image_chrooted
    compress_image


    # Files/bash_profile  # 100s of issues...
    Files/profile

    Files/sbin/post_boot.sh

    Files/bin/aok
    Files/bin/aok_groups
    Files/bin/apt
    Files/bin/disable_sshd
    Files/bin/disable_vnc
    Files/bin/do_fix_services
    Files/bin/elock
    Files/bin/enable_sshd
    Files/bin/enable_vnc
    Files/bin/fix_services
    Files/bin/iCloud
    Files/bin/installed
    Files/bin/ipad_tmux
    Files/bin/iphone_tmux
    Files/bin/pbcopy
    Files/bin/showip
    Files/bin/toggle_multicore
    Files/bin/update
    Files/bin/version
    Files/bin/vnc_start
    Files/bin/what_owns
)

do_shellcheck="$(command -v shellcheck)"
do_checkbashisms="$(command -v checkbashisms)"

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
    if [[ -d /proc/ish ]]; then
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
        shellcheck -x -a -o all -e SC2250,SC2312 "${script}"  || exit 1
    fi
    if [[ "${do_checkbashisms}" != "" ]]; then
        checkbashisms -n -e -x "${script}"  || exit 1
    fi
done
