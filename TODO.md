# TODO

- Generating bzip2 images only results in very moderate size reductions
should be investigated to hopefully generate smaller images.

## Debian setup

Early on there is an error msg

`mount: /proc/mounts: parse error at line 3 -- ignored`

Could be related to is_chrooted() called from is_iCloud_mounted()
examine!

## /etc/motd

check pam settings to see if ithelps

## runbg

use posix script for Debian/Devuan

## idev_ip

 1 MB in Debian
56 kb in Alpine

Room for optimizing the Debian compile?

## Suggested additions to CORE_APKS

mdcat - Markdown reader for the command line that works fine in iSH, unlike glow, which constantly crashes on iSH. Once installed it can be run as mdless, then it uses paging

Only installable in 3.17/edge, on older releases lib dependencies collide

what I use in my .AOK_VARS atm

if [ "$ALPINE_VERSION" = "edge" ]; then
    CORE_APKS="$CORE_APKS mdcat"
elif [ "$ALPINE_VERSION" = "3.17.1" ]; then
    CORE_APKS="$CORE_APKS mdcat@testing"
fi
