#!/bin/sh
# Copyright 2025 Analog Devices Inc.
# Released under MIT licence
#

##############################################################
# Log retrieval script
##############################################################

set -e

PATH=/sbin:/bin:/usr/sbin:/usr/bin
directory=/data/active/etc/log
file=$directory/error_warning_messages

# Create file and set permissions
mkdir -p $directory
touch $file
chmod 640 $file
chown :secure $file


# Boot log retrieval

# Get number of boot errors from device-tree
error_num=$(xxd -p /proc/device-tree/chosen/boot/error-log/errors)
error_num=$(echo $((16#$error_num)))

# Iterate through boot error/warning entries in device tree
error_num=$((error_num - 1))
for i in $(seq 0 "$error_num"); do
  # Insert each boot error message into the system log with the appropriate severity
  entry=$(cat /proc/device-tree/chosen/boot/error-log/error-$i)
  echo "boot: $entry" >> "$file"
done


# Runtime log retrieval

command="/usr/bin/optee_app_adi_runtime_log"  # Command to call OP-TEE TA for retrieval

# Obtain runtime error/warning messages from runtime logs
while true
do
  while read -r line; do
    if echo "$line" | grep -q -e "ERROR:" -e "WARN:" -e "E/TC:" -e "W/TC:"
      then
        echo "runtime: $line" >> "$file"
      fi
  done < <(eval "$command")

  # Repeat runtime log retrieval every 5 seconds
  sleep 5
done
