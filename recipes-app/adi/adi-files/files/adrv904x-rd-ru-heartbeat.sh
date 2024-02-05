#!/bin/bash
# Copyright 2020 - 2023 Analog Devices Inc.
# Released under MIT licence
#

if [ -f /opt/led_apps/scroll_server ]; then
    /opt/led_apps/scroll_server &> /dev/null & #INIT_LED#
else
    echo "HPS LED scroll_server app not found. Aborted LEDs flashing."
    exit 0
fi

toggle_app=/opt/led_apps/toggle
if [ -f $toggle_app ]; then
    echo "HPS LED toggling app found." 
else
    echo "HPS LED toggling app not found. Aborted LEDs flashing."
	exit 0
fi

#stop all scrolling
sleep 0.6 && /opt/led_apps/scroll_client -1  &> /dev/null

#disabled all LEDs except HPS LED7(index 5)
sleep 0.6 && $toggle_app  0 0 &> /dev/null
sleep 0.6 && $toggle_app  1 0 &> /dev/null
sleep 0.6 && $toggle_app  2 0 &> /dev/null
sleep 0.6 && $toggle_app  3 0 &> /dev/null
sleep 0.6 && $toggle_app  4 0 &> /dev/null
sleep 0.6 && $toggle_app  6 0 &> /dev/null
sleep 0.6 && $toggle_app  7 0 &> /dev/null

#total 6 hps LEDs: but just toggle HPS LED7 only
delay1=0.5
for((i=0; i< 0xFFFFFFFF; i++))
do

	  $toggle_app 5 1 &> /dev/null
	  sleep $delay1
	  $toggle_app 5 0 &> /dev/null
	  sleep $delay1
done

exit 0


