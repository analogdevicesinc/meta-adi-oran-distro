#!/bin/bash
# Copyright 2020 - 2024 Analog Devices Inc.
# Released under MIT licence
#
#Description: set mac address routine

#set mac address
if [ -f /etc/netplan/set_mac_address.sh ]; then
    echo "setting mac address..."
    /etc/netplan/set_mac_address.sh &
fi

exit 0
