#!/usr/bin/env bash
#
#  Copyright (c) 2020,2021,2022: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#  Part of https://github.com/jaclu/shell_envs
#
#  Version: 1.0.4 2022-06-11
#

#
#  Runs shellcheck on all included scripts
#

#  shellcheck disable=SC1007
CURRENT_D=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FS_BUILD_D="$(dirname "$CURRENT_D")"

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else.
#
cd "$FS_BUILD_D" || exit 1


checkables=(
    tools/shellchecker.sh      # First self-check :)
    tools/do_chroot.sh

    build_fs
    setup_image_chrooted
    compress_image


    # Files/bash_profile  # 100s of issues...
    Files/profile

    Files/sbin/runbg

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
    Files/bin/post_boot.sh
    Files/bin/showip
    Files/bin/toggle_multicore
    Files/bin/update
    Files/bin/version
    Files/bin/vnc_start
    Files/bin/what_owns
)

for script in "${checkables[@]}"; do
    #  abort as soon as one lists issues
    echo "Checking: $script"
    shellcheck -x "$script"  || exit 1
    checkbashisms "$script"  || exit 1
done
