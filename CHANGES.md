# Changes

I will try to keep track of changes between releases here

## release 0.x.y

- alternate hostname handling for iOS >= 17 rewritten. Now has two modes
1) Static - set custom hostname in /etc/hosts
2) Dynamic - Using a source file fed by an iOS Shortcut tied to the iSH App starting
Defined at build time using ALT_HOSTNAME_SOURCE_FILE, defined post install
by running `/usr/local/bin/aok -H`
- Skips new alternate procedure if version is detected to be < 17 by
checking if /bin/hostname returns other than localhost
- setup_final_tasks.sh ensures all config variables referencing file items
are synced during first-boot on destination device. Any
FIRST_BOOT_ADDITIONAL_TASKS or other scripts refered to must do their own
iCloud syncing if needbe. iCloud is somewhat inconsistent when it comes
to scripts not present on the local device. Sometimes it fails, sometimes
it is synced on a as needed bases. In general the only safe bet is to do
a `find . > /dev/null` this will print out each file not cached as it is
cached.
- wrap deploy script in outer scr to prevent errors from triggering instant
reboot, instead dropping the process to a root shell. This makes it possible
to actually see what went wrong.
- New Debian src-img: Debian10-7-aok-1.tgz
- new Alpine tool apk_find_pkg - give it bin-name returns apk providing bin
- uses installed /etc/skel when creating accounts instead of copying from /opt/AOK
- select_distro uses exit 123 for select_distro_prepare if chrooted
- Changed /usr/local/bin/aok to use echo instead of msg_3 to make it not look like a deploy item
- tools/upgrade_aok_fs.sh make root: own /etc/skel files
- added version notice to select distro
- rsync_chown() -> tools/utils
- tweaked skel files
- ash & bash different prompts - helps you see what the current shell is
- setup_final_tasks.sh now defines a full PATH including /usr/local/bin
- Alpine/etc/profile - added the sbins to common PATH, makes sense since
in most cases this is run by root

## release 0.10.0

- Uses v3.18.4 for Alpine installs
- if no syncfile is given, defaults to use /etc/hostname
- /etc/hostname is updated, on regular iSH just for information, since it cant be used to set hostname there
- Better documentation of hostname_sync.sh and its inittab entries
- typo fixed in copy "$hostname_cached" to /etc/hostname
- updated skel files to handle the custom hostname, when needed
- in setup_final_tasks.sh syncs potentially iCloud related PATH params to ensure content is up to date
- bash prompt setting window title reverted back to ""
- Reverted back to single quote for bash prompts otherwise \$ wont display # for root
- Additional checks for errors in sub-scripts
- Check for error after all apt/apk actions
- getty term linux -> xterm-256color to get default color prompt
- myip rewritten to display all local devices
- showip was found to be redundant, myip should be enough
- whereisthis & whereami installs deps if needed on both Alpine & Debian
- fixed a read without -r

## release 0.9.10

- Added iOS 17 hostname workarounds, added HOSTNAME_SYNC_FILE config
- Added getty's to Alpine & Debian inittab, commented out by default
- reintroduced some skel files unintentionally deleted - .tmux.conf & .vimrc
- shutdown now mentions which host is being shutdown
- tools/init_order info and test scripts to trace script init order

## release 0.9.9

- Devuan: Removed runlevel wait, and not usable prep steps
- Debian & Devuan waits for runlevel default before deploy
- New Debian src-img: Debian10-6-aok-2.tgz
- preparing Debian FS for 1st boot
- procps in general install, since it now works on iSH
- Final tasks does a better job of adjusting config depending on iSH / iSH-AOK
- Updated Alpine/usr_local_bin/aok_groups, to adjust package selection depending on release
- Updated DOCS_APKS to better match what is installed
- Changed Ash prompt somewhat to make it stand out from the Bash prompt. Also added a hint where to change if you do want them to look the same
- ensure ~/.common_rc in sourced early, expanded explaination of purpose

## release 0.9.8

- Updated README - Performance issues running Debian
- Simplified check when toggling Debian cron service
- zsh history config
- New Debian src-img: Debian10-6-aok-1.tgz
- Added things to remove from Debian image
- root shell can only be set to bash or ash during deploy, to ensure
  deploy can complete

## release 0.9.7

- Updated skel files, now ash & zsh setup like bash
- New Debian src-img: Debian10-5-aok-1.tgz
- Added my package adm tools Mapt & Mapk
- Improved detection if already chrooted
- Removed DEBUG_BUILD havent used it in a while and that stuff was going obsolete
- Added check that sudo is installed
- Reintroduced exit after pre-build
- Improved check that chroot dest is not already being used in a chroot
- Alpine & Debian if USE_CRON_SERVICE is not "Y", only actually disable service if it was active, to avoid pointless warning
- do_chroot.sh uses /dev/pts again - some Debian packages gives a warning when not available
- Processing DEB_PKGS_SKIP before DEB_PKGS
- Added override option if do_chroot.sh recomends against running it
- improved checks that chroot is not already active
- improved cleanup of processes after chroot, also works when ps axe is not available

## release 0.9.6

- Sorted out the issue with do_chroot.sh, added a check that kills any stray processes created inside the chroot

## release 0.9.5

- Added warning not to start openrc service on Debian chroot with a Linux host. It will force you to reboot in order to reclaim /dev
- New Debian src-img: Debian10-4-aok-2.tar.gz
- Since all services are disabled in the src_img no longer any need to manually diable them during deploy. Has been so for ages, had just forgotten about it
- filtering more env variables before chroot
  I spent a ridicilos time trying to use env -i, but with no success
  so far, what ends up happening is that the HOME is undefined in the chrooted env. Pretty sure its a trivial fix if you have that know-how - I unfortunately dont.
  common_AOK/cron/periodic
- cron (dcron for Alpine) will always be installed and configured
  The service will only be activated if USE_CRON_SERVICE is "Y"
- common_AOK/etc/skel/.tmux.conf - Fixed typo
- nav_keys.sh - Can now be used in scrips, give desired navkey as param
- removed Debian/etc/init.d/runbg - I figured out that the generic openrc runbg works just as fine on Debian
- removed some utils - fingers purpose illudes me on a one user system, and the option to automount /iCloud has made a sepate util redundant
  common_AOK/usr_local_bin/finger
  common_AOK/usr_local_bin/iCloud

## release 0.9.4

- Adding repo [Edge testing](https://dl-cdn.alpinelinux.org/alpine/edge/testing) Both for edge and rescent Alpine releases. For non edge releases testing is hidden behind @testing
- Alpine/usr_local_sbin/update_motd now can extract Alpine relese both from regular releases and edge ones.
- Rewrote handling of edge releases, now integrated with rest of build.
- For Alpine builds, check that ALPINE_VERSION is defined

## release 0.9.3

Changes not logged up to this point
