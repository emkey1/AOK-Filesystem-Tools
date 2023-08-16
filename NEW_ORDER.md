# VFS Builder

Creates a FS for iSH and similar

===  Prebuild or on 1st boot  ===

access tarball

untar it

pkg mngr - update upgrade

if not prebuild
    Handle user options - TZ, Extra FS mounts...

install additional distro software

install AOK

deploy AOK bins

Prepare /etc in general on targget

deploy AOK custom stuff - services etc

define how to indicate base deploy is completed

===  On Dest platform  ===

if was prebuild
    Handle user options - TZ, Extra FS mounts...

Mount external fs

Deploy custom user
