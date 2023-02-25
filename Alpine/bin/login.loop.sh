#!/bin/sh

while true; do
    [ -f /etc/issue ] && cat /etc/issue
    /bin/busybox login
done
