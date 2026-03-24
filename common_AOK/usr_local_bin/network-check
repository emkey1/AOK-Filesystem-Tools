#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023-2024: Jacob.Lundqvist@gmail.com
#
#  Reports network status
#

ping_tst_node=8.8.8.8
dns_tst_node=amazon.com

#
#  When chrooted ping must be run with sudo - odd ...
#
if [ -f /etc/opt/AOK/this_fs_is_chrooted ]; then
    cmd="sudo ping"
else
    cmd="ping"
fi

if $cmd -c 2 "$ping_tst_node" >/dev/null 2>&1; then
    if $cmd -c 2 "$dns_tst_node" >/dev/null 2>&1; then
        echo "Connected to the Internet and DNS is resolving!"
	ex_code=0
    else
        echo "***  DNS does not seem to resolve!"
	ex_code=2
    fi
else
    echo "***  Not able to access the Internet!"
    ex_code=1
fi
echo
exit "$ex_code"
