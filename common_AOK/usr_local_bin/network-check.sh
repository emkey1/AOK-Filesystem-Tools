#!/bin/sh

if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    if ping -c 2 google.com >/dev/null 2>&1; then
        echo
        echo "Connected to the Internet and DNS is resolving!"
    else
        echo
        echo "***  DNS does not seem to resolve!"
    fi
else
    echo
    echo "***  Not able to access the Internet!"
fi
echo
