#!/bin/bash
# Copyright 2020 - 2024 Analog Devices Inc.
# Released under MIT licence
#
#Description: The default MAC setup routine

#Ref to QSG for instructions
ip link set dev eth0 down
ip link set dev eth0 address 00:05:F7:6c:00:30
ip link set dev eth0 up
