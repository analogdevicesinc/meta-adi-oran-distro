#!/bin/bash
# Copyright 2020 - 2023 Analog Devices Inc.
# Released under MIT licence
#
#Description: adrv904x-rd-ru powering off service

result=$(which uiomem)
if [[ $result != *"uiomem"* ]] ; then
    echo -e "\nuiomem is not found, exited!\n"
    exit 1
else
    echo "adrv904x-rd-ru powering off..." 

    #Set bit15 of register 0xF9142820 to cutting off power for Adrv904x-rd-ru, 
    #1)if 180K Ohms installed to R150, an auto cold reset(full system) is 
    #achieved for Adrv904x-rd-ru; 
    #2)if R150 remains with 187K, after the command is sent, press the 
    #push button S2 to power on the Adrv904x-rd-ru to obtain the full cold reset.
    uiomem 0xF9142820 0x8000 &> /dev/null
fi

exit 0
