#!/bin/bash
# Copyright 2024 Analog Devices Inc.
# Released under MIT licence
#
# Description: push button monitoring script

set -e

pushbutton_mon()
{
    # Pushbutton is in GPIO controller number(0) and line number(GPIO_51)
    GPIO_CTRL=0
    LINE_NO=51
    delay=0.2s

    # check libgpiod tool installed or not
    result=$(which gpioget)
    if [ ! -f "${result}" ]; then
        wall "libgpiod is not installed, exited!\n"
        exit 1
    fi

    # all day monitoring
    while [ 1 ];
    do
        for((i=1; i<6; i++))
        do
            # read gpio signal value
            VALS[i]=$(gpioget -a -c "${GPIO_CTRL}" "${LINE_NO}")
            echo -e "\nval = ${VALS[i]}!\n"  &> /dev/null
            sleep $delay
        done

        if [[ "${VALS[4]}" == "0" && "${VALS[5]}" == "0" ]]; then
            # for every passed 5 times read(200ms interval), if the last two
            # reads are all low(active), user pressing button is detected.
            echo "Powerdown button pressed. System is shutting down..."
            halt
            break
        fi
    done
}

pushbutton_mon &
