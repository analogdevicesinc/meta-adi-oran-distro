#!/bin/sh
# Copyright 2024 Analog Devices Inc.
# Released under MIT licence
#

##############################################################
# Factory reset script
##############################################################

set -e

PATH=/sbin:/bin:/usr/sbin:/usr/bin

logger "Factory reset..."

# Add factory-reset flag to bootcfg partition to signal to TF-A to clear partition
/usr/sbin/update-bootcfg.sh "--factory-reset" "1"

# Log timestamp of factory reset to trigger clearing of partition on next boot as part of the data-partition initialization
date +"%Y-%M-%d %H:%M" > "/data/active/reset/factory-reset"

# Reboot
/sbin/reboot
