#!/bin/sh
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#
#  Final steps of Alpine setup, things that needs to run on the destination
#  platform
#


# Set some variables
# shellcheck disable=SC1091
. /opt/AOK/BUILD_ENV


msg_1 "Final Alpine setup steps"


#  Will be run again in post_boot.sh, but since some tasks are done before
#  That happens, it makes sense to run it now
/usr/local/sbin/fix_dev



if ! build_status_get "$STATUS_IS_CHROOTED" ; then
    #
    #  Run this after services has been activated, so that check they run
    #  is meaningful
    #
    openrc_might_trigger_errors
    /usr/local/sbin/post_boot.sh foreground
else
    msg_2 "Skipping post_boot.sh when chrooted"
fi

#
#  Setup Initial login mode
#
msg_2 "Setting defined login mode: $INITIAL_LOGIN_MODE"
#  shellcheck disable=SC2154
/usr/local/bin/aok -l "$INITIAL_LOGIN_MODE"

msg_2 "Preparing initial motd"
/usr/local/sbin/update_motd

msg_1 "Setup complete!"
echo

# Not the right place to set profile, since this can be called in different ways

build_status_clear "$STATUS_BEING_BUILT"
