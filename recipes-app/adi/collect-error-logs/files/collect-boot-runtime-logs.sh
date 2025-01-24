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
mkdir $directory
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
type=0   # 1 is for BL31 buffer, 2 is for OP-TEE buffer

# Obtain runtime error/warning messages from runtime logs
while true
do
  while read -r line; do
    # Check for signal of BL31 buffer
    if echo "$line" | grep -q "BL31 Buffer"
    then
      type=1
      continue
    # Check for signal of OP-TEE buffer
    elif echo "$line" | grep -q "OP-TEE Buffer"
    then
      type=2
      continue
    fi

    # Parse BL31 messages
    if [ "$type" -eq "1" ]; then
      if echo "$line" | grep -q "ERROR:"
      then
        echo "runtime: $line" >> "$file"
      elif echo "$line" | grep -q "WARN:"
      then
        echo "runtime: $line" >> "$file"
      fi
    # Parse OP-TEE messages
    elif [ "$type" -eq "2" ]; then
      if echo "$line" | grep -q "E/TC:"
      then
        echo "runtime: $line" >> "$file"
      elif echo "$line" | grep -q "W/TC:"
      then
        echo "runtime: $line" >> "$file"
      fi
    fi
  done < <(eval "$command")

  # Repeat runtime log retrieval every 5 seconds
  sleep 5
done
