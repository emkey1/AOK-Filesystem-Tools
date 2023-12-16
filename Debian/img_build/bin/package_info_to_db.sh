#!/bin/bash
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2021-2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Creates a DB on installed apts, and cathegorizes apts by sections
#  I use this when creating a base image for AOK-Filesystems-Tools
#  ensuring nothing un-needed is left in.
#

#
#
#  Sample usages
#
# sqlite3 /tmp/package_info.db 'select priority,section,name,is_leaf FROM packages ORDER By priority,section,is_leaf,name'

database="/tmp/package_info.db"

#  Always build from scratch
rm -f "$database"

sqlite3 "$database" <<EOF
CREATE TABLE IF NOT EXISTS packages (
    priority TEXT,
    section TEXT,
    name TEXT,
    is_leaf TEXT
);
EOF

echo ">>> db created"

# Function to print a progress dot
print_progress_dot() {
    echo -n "."
}

#
#  Checking dependencies inside iSH would take longer than forever,
#  so on iSH skip this check
#
if [[ ! -d /proc/ish ]]; then
    check_dependencies=1
fi

# Iterate over all installed packages
for package in $(dpkg-query -f '${Package}\n' -W); do
    #
    #  Check if the package has dependencies

    is_leaf="" #  Defaults to not be a leaf
    if [[ "$check_dependencies" = 1 ]]; then
        # If the package has no dependencies, it's a leaf package
        if ! apt-cache depends "$package" 2>/dev/null | grep -q "Depends:"; then
            is_leaf="*"
        fi
    fi

    # Get package section and priority
    section=$(dpkg-query -f '${Section}\n' -W "$package")
    priority=$(dpkg-query -f '${Priority}\n' -W "$package")

    # Store the package in the appropriate array
    sqlite3 "$database" "INSERT INTO packages (priority, section, name, is_leaf) \
	VALUES ('$priority', '$section', '$package', '$is_leaf');"

    print_progress_dot
done

echo "Package information has been stored in '$database'."
