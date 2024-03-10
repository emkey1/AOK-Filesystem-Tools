#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Varios things used at multiple places during Debian installs
#

initial_fs_prep_debian() {
    msg_2 "initial_fs_prep_debian()"

    #
    #  This modified inittab is needed on firstboot, in order to be
    #  able to set runlevels, it forcefully clears /run/openrc before
    #  going to runlevel S
    #
    msg_3 "FamDeb AOK inittab"
    cp -a "$d_aok_base"/FamDeb/etc/inittab "$d_build_root"/etc

    # msg_3 "initial_fs_prep_debian() - done"
}

#===============================================================
#
#   Main
#
#===============================================================

[ -z "$d_aok_base_etc" ] && . /opt/AOK/tools/utils.sh
