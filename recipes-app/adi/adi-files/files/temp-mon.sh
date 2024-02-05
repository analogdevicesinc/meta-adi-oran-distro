#!/bin/bash
# Copyright 2020 - 2023 Analog Devices Inc.
# Released under MIT licence
#
#Description: System temperature monitor routine which adjusts fan speed to 
#cool system down based on measured temperature values.

FAN_CTRL_REG="0xF9140150"
CHIP_ID="0x4D"
CHIP_ADDR="0x4D"

#test i2c-tool availability
result=$(which i2cget)
if [[ $result != *"i2cget"* ]] ; then
    echo -e "\ni2cget is not found, exited!\n"  
    exit 1
fi

w_flag=""
result=$(which uiomem)
if [[ $result != *"uiomem"* ]] ; then
    echo -e "\nuiomem is not found, trying to find devmem2\n"
    result=$(which devmem2)
    if [[ $result != *"devmem2"* ]] ; then
        echo -e "\ndevmem2 is not found, exited!\n"  
        exit 1
    else
        rwtool=devmem2
        w_flag=w
    fi
else
    rwtool=uiomem
fi

echo -e "\nrwtool = ${rwtool}\n"
echo -e "\nw_flag = ${w_flag}\n"

#Sleep is 10s.
delay=10s

#default is styx/samana-on-styx
PLATFORM=styx

#fetch and judge the platform
result=$(cat /etc/environment)
if [[ $result == *"kerberos"* ]]; then
    PLATFORM=kerberos
fi

#I2C bus number for temp sensor, styx/samana-on-styx: 1, Keberos: 4
if [[ $PLATFORM == *"styx"* ]]; then
    TEMP_BUS=1
    NUM_BUS=5
else
    TEMP_BUS=4
    NUM_BUS=8
fi

echo -e "\nUsing i2c temp senosr bus${TEMP_BUS} for accessing.\n"
chip_id=$(i2cget -y "${TEMP_BUS}" "${CHIP_ADDR}" 0x0A)
echo -e "\nchip_id = ${chip_id}!\n"  
if [[ "$chip_id" -ne "$CHIP_ID" ]]; then
    wall "\nUnrecognized temp sensor chip ID! Exited!\n"  
    exit 0
fi

#temp channel 1 is selected
TEMP_CH=1

#starts with 25degC, temp range is from 0 ~ 255
temp=25

#Fan Speed Control 0x00 ~0x1F
speed_prev=0

for((i=0; i<0xFFFFFFFF; i++))
do
    #check OVERTEMP firstly
    overtemp=$(i2cget -y "${TEMP_BUS}" "${CHIP_ADDR}" 0x45)
    OVERTEMP_MASK=$(((2**NUM_BUS)-1))
    echo -e "\nOVERTEMP_MASK = ${OVERTEMP_MASK}!\n"
    overtemp_sig=$(( overtemp&OVERTEMP_MASK ))
    if [[ "$overtemp_sig" -gt "0" && "$i" == "0" ]]; then
        wall "Board error. Rework for platform boards are needed to run the temp monitoring. Exiting.."
        exit 1
    fi

    echo -e "\novertemp = ${overtemp}!\n"  
    if [[ "$overtemp" -gt "0" ]]; then
        wall "Over temperature detected! System shutdown now!"  
        shutdown -h 0
    fi

    #check ALERT
    alert=$(i2cget -y "${TEMP_BUS}" "${CHIP_ADDR}" 0x44)
    echo -e "\nalert = ${alert}!\n"
    if [[ $alert -gt 0 ]]; then
        wall "Hot alert! Fan speed is set to HIGH until alert released!"
        $rwtool ${FAN_CTRL_REG} ${w_flag} 0x1E >> /dev/null
    else
        temp=$(i2cget -y "${TEMP_BUS}" "${CHIP_ADDR}" "${TEMP_CH}")
        echo -e "\nCurrent temperature is ${temp}\n"

        #check LUT for speed setting
        speed=$((($temp + 7)/8-1))

        #hex format to send to uiomem or devmem2
        speed="0x$(printf "%X\n" ${speed})"
        echo -e "\nspeed = ${speed}\n"  
        if [[ $speed != ${speed_prev} ]]; then
            echo -e "\nChanging fan speed from ${speed_prev} to ${speed},\
            max = 0x1F.\n" 
            $rwtool ${FAN_CTRL_REG} ${w_flag} ${speed} >> /dev/null
        fi

        speed_prev=$speed
        echo -e "\nspeed_prev = ${speed_prev}\n"      
    fi

    sleep $delay
done

