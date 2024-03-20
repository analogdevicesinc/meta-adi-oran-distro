#!/bin/sh
# Copyright 2023 Analog Devices Inc.
# Released under MIT licence
#

##############################################################
# Secondary launcher script
# Performs steps needed to launch Linux env on secondary tile
##############################################################

set -e

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Parameters for secondary UART console (A55-to-A55 virtual UART)
CONSOLE_DEV_NAME=ttyAMA6
CONSOLE_DEV="/dev/$CONSOLE_DEV_NAME"
CONSOLE_BAUD=4000000
CONSOLE_LOG_FILE="/tmp/$CONSOLE_DEV_NAME.log"

# Parameters for PPP network link
PPP_DEV_NAME=ttyAMA6
# TODO: SystemC uses physical UART due to vUART latency issues
# Remove this if/when SystemC support is removed
PLAT=$(cat /proc/device-tree/chosen/boot/plat)
if [ ${PLAT} = "sysc" ]
then
	PPP_DEV_NAME=ttyAMA4
fi
PPP_DEV="/dev/$PPP_DEV_NAME"
PPP_BAUD=4000000
PPP_LINK_TIMEOUT=10
PPP_LINK_TIMEOUT_MS=$(expr $PPP_LINK_TIMEOUT \* 1000)
PRIMARY_IP_ADDR=169.254.1.1
SECONDARY_IP_ADDR=169.254.1.2

# Device tree flags for dual-tile and secondary Linux
DT_DUAL_TILE_FLAG=/proc/device-tree/chosen/boot/dual-tile
DT_SECONDARY_LINUX_FLAG=/proc/device-tree/chosen/boot/secondary-linux-enabled

# Parameters for boot success check
BOOT_TIMEOUT=60
BOOT_TIMEOUT_MS=$(expr $BOOT_TIMEOUT \* 1000)
BOOT_SUCCESS_STR="Secondary tile is active. Halting boot."

if [ -f "$DT_DUAL_TILE_FLAG" ]
then
	if [ -f "$DT_SECONDARY_LINUX_FLAG" ]
	then
		# Setup logging on the virtual UART
		echo "Setting up console on $CONSOLE_DEV..."
		stty -F $CONSOLE_DEV speed $CONSOLE_BAUD
		socat -u $CONSOLE_DEV,b$CONSOLE_BAUD,raw STDOUT > $CONSOLE_LOG_FILE 2>&1 & SOCAT_PID=$!

		# Call the OP-TEE TA to initiate secondary boot
		echo "Initiating secondary boot..."
		/usr/bin/optee_app_secondary_launcher

		# Wait up to BOOT_TIMEOUT seconds for the required BOOT_SUCCESS_STR
		# to appear in the secondary's boot log
		echo "Waiting up to $BOOT_TIMEOUT seconds for secondary to start..."
		NEXT_WAIT_TIME=0
		until [ $NEXT_WAIT_TIME -eq $BOOT_TIMEOUT_MS ] || grep "$BOOT_SUCCESS_STR" $CONSOLE_LOG_FILE > /dev/null 2>&1; do
			sleep 0.001
			NEXT_WAIT_TIME=$((NEXT_WAIT_TIME+1))
		done
		grep "$BOOT_SUCCESS_STR" $CONSOLE_LOG_FILE > /dev/null 2>&1
		RESULT=$?
		if [ $RESULT -ne 0 ]
		then
			echo "ERROR: Timed out waiting for secondary to start"
			exit 1
		fi
		echo Done

		# Stop logging on virtual UART
		kill $SOCAT_PID

		# Bring up the PPP network link over virtual UART
		echo "Waiting up to $PPP_LINK_TIMEOUT seconds to establish PPP link..."
		pppd $PPP_DEV lock noipv6 asyncmap 0 local $PRIMARY_IP_ADDR:$SECONDARY_IP_ADDR $PPP_BAUD xonxoff nodetach call adrv906x-secondary > /dev/null 2>&1 &
		NEXT_WAIT_TIME=0
		until [ $NEXT_WAIT_TIME -eq $PPP_LINK_TIMEOUT_MS ] || ifconfig ppp0 2> /dev/null | grep "UP POINTOPOINT"  > /dev/null 2>&1; do
			sleep 0.001
			NEXT_WAIT_TIME=$((NEXT_WAIT_TIME+1))
		done
		ifconfig ppp0 2> /dev/null | grep "UP POINTOPOINT"  > /dev/null 2>&1
		RESULT=$?
		if [ $RESULT -ne 0 ]
		then
			echo "ERROR: Timed out waiting to establish PPP link"
			exit 1
		fi
		echo Done

		# Verify network is up betwen primary and secondary
		echo "Checking network connectivity between primary and secondary..."
		ping -c 1 -W 1 $SECONDARY_IP_ADDR > /dev/null 2>&1
		RESULT=$?
		if [ $RESULT -ne 0 ]
		then
			echo "ERROR: Failed to ping secondary at $SECONDARY_IP_ADDR"
			exit 1
		fi
		echo Done
	else
		echo "ERROR: Linux not enabled on secondary tile. Can't launch secondary tile."
		exit 1
	fi
else
	echo "ERROR: Not a dual-tile system. Can't launch secondary tile."
	exit 1
fi
