# Creating Debian Images for ISH

Since iSH is so slow, deploying packages is better done in advance.
For this reason the Debian image comes with all the AOK FS stuff
pre installed. You can add or drop packages during prebuild in order to
get the content to match your expectations without having to add/delete
apt packages on the device itself.

## aok_img_prepare.sh

Prepares a Debian10-minim-x image by ensuring that the apt cache is
present, and doing an apt upgrade

## aok_img_populate.sh

Populates a Debian10-minim-x image into an Debian10-x-aok-y ready to
be used to build an AOK-Filesystems-Tools Debian10 image
It is recomended to cancel all "Configuring tzdata" menus, and let
the installing user choose the right TZ

## aok_image_cleanup.sh

Prepare image to be used as a DEBIAN_SRC_IMAGE

## image-history.txt

Keeps track of changes in the Debian1-minim-X File system, used as
base for the AOK FS Debian iMages that come with the standard tools
preinstalled.

## bin/

Some extra tools helping in preparing the FS, by keeping them in
one place its easy to copy over to the build env

### bin/cleanup_minim.sh

Gets rid of all cashes and other items that will be rebuilt if
when needed without causing any actual loss of config or data
All to keep the Debian10-minim-X file size down

### bin/Mapt

apt helper that runs all the usual maintenance tasks, and also
lists anything that can be purged

### bin/package_info_to_sqlite.sh

Generates a db over installed packages allowing hierarchial display

### bin/populate-deb-aok-img.sh

Installs all the default AOK FS software, and cleans out some
stuff not meaningfull on iSH-AOK
