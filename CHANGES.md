# Changes

I will try to keep track of changes between releases here

## Changes newest first

- removed Debian/etc/init.d/runbg
I figured out that the generic runbg works just as fine on Debian
- removed some utils
common_AOK/usr_local_bin/finger
common_AOK/usr_local_bin/iCloud


## release 0.9.4

- Adding repo https://dl-cdn.alpinelinux.org/alpine/edge/testing Both for edge and rescent Alpine releases. For non edge releases testing is hidden behind @testing
- Alpine/usr_local_sbin/update_motd now can extract Alpine relese both from regular releases and edge ones.
- Rewrote handling of edge releases, now integrated with rest of build.
- For Alpine builds, check that ALPINE_VERSION is defined

## release 0.9.3

Changes not logged up to this point
