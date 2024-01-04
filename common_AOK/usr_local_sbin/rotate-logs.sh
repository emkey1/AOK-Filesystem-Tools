#!/bin/sh

LOG_DIR="/var/log"

for log_file in "$LOG_DIR"/*log; do
    [ "$log_file" = "lastlog" ] && continue
    file_size="$(stat --printf="%s" "$log_file")"
    echo "><> $file_size  $log_file"
    if [ -f "$log_file" ] && [ "$file_size" -gt 20480 ]; then # > 20k
	# Set the file paths
	rotated_log_file="$(dirname "$log_file")/$(date +"%y%m%d-%H%M%S")-$(basename "$log_file")"

	if [ "$(file -b "$log_file")" = "data" ]; then
	    #  non text files needs to be moved as is
	    mv "$log_file" "$rotated_log_file"
	    continue
	fi

	# Count the total number of lines in the syslog file
	total_lines=$(wc -l < "$log_file")

	# Calculate the number of lines to exclude (last ten lines)
	exclude_lines=$((total_lines - 10))

	# Use sed to copy all lines except the last ten to the new file
	sed "1,${exclude_lines}d" "$log_file" > "$rotated_log_file"

	# Truncate the original file, removing the copied lines
	sed -i "1,${exclude_lines}d" "$log_file"
    fi
done
