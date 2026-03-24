#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023-2024: Jacob.Lundqvist@gmail.com
#
#  Rotates logs > max_size
#

handle_binary_file() {
	#  non text files needs to be moved as is
	mv "$log_file" "$rotated_log_file"
	gzip "$rotated_log_file"
	/usr/loca/bin/logger rotate-logs "Rotated $rotated_log_file"
}

handle_text_file() {
	# Count the total number of lines in the syslog file
	total_lines=$(wc -l <"$log_file")

	# Calculate the number of lines to exclude (last ten lines)
	exclude_lines=$((total_lines - 10))

	# Use sed to copy all lines except the last ten to the new file
	sed "1,${exclude_lines}d" "$log_file" >"$rotated_log_file"
	gzip "$rotated_log_file"
	/usr/local/bin/logger rotate-logs "Rotated $log_file -> $rotated_log_file"

	#
	# Truncate the original file, removing the copied lines
	# this aproach allows for the logfile to grow during the rotation
	#
	sed -i "1,${exclude_lines}d" "$log_file"
}

#===============================================================
#
#   Main
#
#===============================================================

d_log="/var/log"
max_size=20480 # 20 kB

for log_file in "$d_log"/*; do
	[ "$(basename "$log_file")" = "lastlog" ] && continue # special file
	[ -f "$log_file" ] || continue                        # not a file

	file_size="$(stat -c '%s' "$log_file")"
	[ -f "$log_file" ] && [ "$file_size" -gt "$max_size" ] && { # > 20k
		# Set the rotated file name
		_fn="$(dirname "$log_file")/$(date +"%y%m%d-%H%M%S")"
		_fn="${_fn}-$(basename "$log_file")"
		rotated_log_file="$_fn"

		if file -b "$log_file" | grep -q text; then
			handle_text_file
		else
			handle_binary_file
		fi
	}
done
exit 0
