#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#
#  This is a hack to reset /run into a state with no services running,
#  if this is not done, upon boot openrc will think services are running
#  and thus wont start them, additionally will refuse to stop the non
#  existing services since no matching pids can be found.
#

# Debug log
echo "[$(date)]  reset-run-dir.sh" >>/var/log/debug.log

rm /run -rf
mkdir /run
cd /run
tar xvfz /etc/opt/openrc_empty_run.tgz
