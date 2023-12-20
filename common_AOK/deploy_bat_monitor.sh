#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Deploys bat-monitord, and its service script
#
#  This logs changes in battery charge, and exessive uptimes
#

service_name="bat-monitord"

hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
. /opt/AOK/tools/utils.sh

d_base=$(cd -- "$(dirname -- "$0")" && pwd)


this_is_aok_kernel  || {
    msg_2 "$service_name is only meaningfull on iSH-AOK, skipping"
    exit 0
}

msg_2 "Installing battery monitoring service: bat_monitord"

msg_3 "Deploying $service_name"
cp -a "$d_base"/bin/"$service_name" /usr/local/sbin

msg_3 "Deploying init.d script"
cp -a "$d_base"/init.d/"$service_name" /etc/init.d

msg_3 "Adding $service_name service"
rc-update add "$service_name" default
msg_3 "Restarting service, in case config changed"
rc-service "$service_name" restart

msg_2 "service $service_name installed and enabled"
echo
