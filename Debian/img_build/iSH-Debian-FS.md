
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
