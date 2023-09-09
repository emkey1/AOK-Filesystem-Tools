
# Files related to generation of DEBIAN_SRC_IMAGE

Be aware that theese are just reference copies, for easy access
and might not always be up to date.

The canonical location is on the DEBIAN_SRC_IMAGE /root/img_build
those are the files related to building that specific image

## package_info_to_sqlite.sh

A script that logs all installed apts into a DB, storing
  priority
  section
  name
  is_leaf (a package with no dependencies)


A recursive dependency check would take far too long on iSH so by default
leaf checks is not done when Debian is running on iSH

Once generated, get a sorted overview of installed packages by running

sqlite3 /tmp/package_info.db 'select priority,section,name,is_leaf FROM packages ORDER By priority,section,is_leaf,name'
