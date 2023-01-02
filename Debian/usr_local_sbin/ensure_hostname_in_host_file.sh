#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Ensure that hostname is in /etc/hosts, if not

host_file="/etc/hosts"
host_name="$(hostname | tr '[:upper:]' '[:lower:]')"

echo "Ensuring hostname is in $host_file"
if ! grep -q "$host_name" "$host_file"; then
    echo "adding hostname: $host_name to $host_file"
    echo "127.0.0.1\t$host_name" >>"$host_file"
fi
