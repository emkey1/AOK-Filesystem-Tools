#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  What is said here for Debian, also goes for Devuan
#
#  Prepares a Debian10-minim-x image by ensuring that the apt cache is
#  present, then chains to aok_image_populate.sh
#

aiprep_time_start="$(date +%s)"
aiprep_prog_name=$(basename "$0")
d_here="$(dirname "$0")"

. /opt/AOK/tools/utils.sh
# shellcheck source=/dev/null
. "$d_here"/img_build_utils.sh

#
#  Since the minim FS comes with caches cleared, an apt update
#  is needed to repopulate the cache for the packet manager
#
msg_1 "Do update in case caches are gone"
apt update || error_msg "apt update issue"
health_check

duration="$(($(date +%s) - aiprep_time_start))"
display_time_elapsed "$duration" "$aiprep_prog_name"

next_task="$d_here"/aok_img_populate.sh
msg_1 "aok_img_prepare.sh done - chaining to $next_task"
$next_task
