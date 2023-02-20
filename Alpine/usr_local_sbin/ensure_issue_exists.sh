#!/bin/sh

#
#  Login crashes if /etc/issue is not pressent.
#  This ensures at least an empty file is there
#
if [ ! -e /etc/issue ]; then
    /bin/touch /etc/issue
fi
