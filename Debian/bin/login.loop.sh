#!/bin/sh

while true; do
    [ -f /etc/issue ] && cat /etc/issue
    /bin/login.original
done
