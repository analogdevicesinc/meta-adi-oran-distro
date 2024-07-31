#!/bin/bash
# Copyright 2022 - 2024 Analog Devices Inc.
# Released under MIT licence
#
#Description: platform startup configuration routine

echo -e "\nExecuting platform startup configuration\n"

# enable the AMP power(bit14) and trun on transiver/Koror(bit13) at power on.
# Register 0xF9142820's default value is normally 0x2D0(readback firstly)
val_set=0x6000
val_read=$(uiomem 0 0 0x142820)
regexVer='[0-9a-fA-Fx]+'
if [[ $val_read =~ (Readback )($regexVer) ]]
 then
  val_read="${BASH_REMATCH[2]}"
  #echo -e "Value readback for regiser 0xF9142820:${val_read}\n"
 else
  val_read="0";
  wall "Value readback error for regiser 0xF9142820."
fi

#echo -e "${val_read}\n"
val_write=$(($val_read | $val_set))
val_write="0x$(printf "%X\n" ${val_write})"
#echo -e "${val_write}\n"
uiomem 0 0 0x142820 ${val_write} &> /dev/null
uiomem 0 0 0x142820 &> /dev/null #readback to check.


if [ -f ./recal_corepll.sh ]; then
    echo "Running recal corepll script..."
    sudo ./recal_corepll.sh &
fi

# Launch MQTT Broker
mosquitto -d

#mount /dev/mmcblk0p1 /mnt

exit 0
