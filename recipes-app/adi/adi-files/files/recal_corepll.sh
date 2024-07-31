#!/bin/bash
# Copyright 2022 - 2024 Analog Devices Inc.
# Released under MIT licence
#
#Description: re-calibration for core pll.

AD9528_PLL2_LOCK_TIMEOUT_SECONDS=5
FPGA_CORE_PLL_LOCK_TIMEOUT_SECONDS=5

# ==========================================================================================================
# read the AD9528's PLL2 lock status - a positive indication that the AD9528 is has been configured and 
# running. Not an abolute indication that the 245.76MHz JESD "core" clock is valid however (but close).
# ==========================================================================================================

# Check whether the AD9545 kernel module is loaded
if ! [ -f /sys/bus/iio/devices/iio:device0/pll2_locked ]; then
	echo "ERROR: AD9528 driver not loaded (could be caused by an error during initialisation of AD9528). Exiting script."
        exit
fi

start_ts=$EPOCHSECONDS
# read the current AD9528 PLL2 lock status via driver
read ad9528_lock_status < /sys/bus/iio/devices/iio:device0/pll2_locked

# Checking for AD9528 PLL2 lock. Timeout and report error if necessary
while [ $ad9528_lock_status -eq 0 ] ;
do
      sleep 0.5
      read ad9528_lock_status < /sys/bus/iio/devices/iio:device0/pll2_locked

      now_ts=$EPOCHSECONDS
      elapsed=$((now_ts - start_ts))

      if [ $(( now_ts - start_ts )) -gt $AD9528_PLL2_LOCK_TIMEOUT_SECONDS ]; then 
	     echo "Error: AD9528 PLL2 isn't locked - exiting."
	     exit
      fi
done

# If control arrives here then the AD9528 PLL2 is locked
echo "AD9528 is configured and running - PLL2 is locked."

# The outputs of the AD9528 should be stable soon after (or concurrent) with PLL2 
# showing locked. The fact that other modules are loaded after the AD9528 will mean
# that by the time control arrives here, the AD9528 outputs are stable. Add a short
# dwell period just to be sure.
sleep 0.2

# ===============================================================================
# Check the FPGA CORE PLL (IOPLL block) lock status before recalibration
# process is instigated. Lock status available via FPGA register 0xF9022004, bit0.
# ===============================================================================
status=`uiomem 0 0 0x022004 | grep "^from addr" | awk -F " " '{print $NF}'`

if [ "$status" = "0x00000001" ] ; then
    echo "Before recalibration: CORE PLL is locked."
else
    echo "Before recalibration: CORE PLL is unlocked."
fi

# ======================================
# Run the CORE PLL calibration process
# ======================================
echo "Running CORE PLL recalibration..."

uiomem 0 0 0x021800 b 0x00 > /dev/null

echo "CORE PLL recalibration complete."

# =======================================================
# Read the CORE PLL lock status after IOPLL recalibration
# =======================================================
start_ts=$EPOCHSECONDS

# Initialise the lock status as being unlocked on entry to while loop
status="0x00000000"

while [ "$status" = "0x00000000" ] ;
do
     # check the locks status
     status=`uiomem 0 0 0x022004 | grep "^from addr" | awk -F " " '{print $NF}'`
     if [ "$status" = "0x1" ] ; then
	     echo "Success: CORE PLL is locked following recalibration."
	     exit
     fi

     # timeout if necesaary
     now_ts=$EPOCHSECONDS
     elapsed=$((now_ts - start_ts))

     if [ $(( now_ts - start_ts )) -ge $FPGA_CORE_PLL_LOCK_TIMEOUT_SECONDS ] ; then
             break
     fi
done

# If control arrives here then the the core pll is unlocked
echo "ERROR: CORE PLL not locked!"

