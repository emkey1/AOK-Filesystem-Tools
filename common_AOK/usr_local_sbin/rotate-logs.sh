#!/bin/sh

LOG_DIR="/path/to/your/logs"

for log_file in "$LOG_DIR"/*log; do
    if [ -f "$log_file" ] && [ "$(stat --printf="%s" "$log_file")" -gt 10240 ]; then
        mv "$log_file" "$log_file.$(date +%Y%m%d%H%M%S)"
    fi
done
