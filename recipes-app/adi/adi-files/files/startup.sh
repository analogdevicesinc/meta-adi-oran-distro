#!/bin/bash
# Copyright 2020 - 2023 Analog Devices Inc.
# Released under MIT licence
#
#Description: platform startup configuration routine

echo -e "\nExecuting platform startup configuration\n"
echo -e "\nNetwork was configured based on /etc/netplan/*config.yaml\n"
#ENABLE-TRANSCEIVERS#
cat /etc/netplan/*config.yaml
echo -e "\n"
#mount /dev/mmcblk0p1 /mnt

exit 0
