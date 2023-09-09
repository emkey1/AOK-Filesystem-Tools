# TODO

##  Move do_shutdwn

/usr/local/lib ??

##  Make it more clear how to refer to self during deploy


When the deploy starts its pretty clear what `hostfs_is_alpine` and
`destfs_is_alpine` is refering to. However when the destfs boots up and
does a large part of the deploy itself, shouldnt it be the host?

Perhaps it should be seen as a chroot thing. If something is working
chrooted on a buildhot it would make most sense to see that as a
destfs in this context, but if the same deploy steps happens on the
deploy target, running the deploy as its primary env it would ssem to be
the hostfs. More clarity about how to refer to different roles needs to
be found.


## iSH Debian

When prebuilding /etc/opt/AOK is created in the host FS prior to chroot
