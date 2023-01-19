#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Needs to run on destination platform, build idev_ip.c and install into
#  /usr/local/bin
#

# shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV

make_cmd="$(command -v make)"
if [ -x "$make_cmd" ]; then
    # shellcheck disable=SC2154
    if ! bldstat_get "$STATUS_IS_CHROOTED"; then
        msg_1 "Building and installing idev_ip"
        cd "$aok_content"/common_AOK/src || exit 99
        make install
    else
        msg_1 "Will not build idev_ip in chrooted env"
    fi
else
    msg_1 "No build env, idev_ip can't be built"
fi
