#! /bin/sh

set -e
count=0
while : 
do
#don't enable setting gpio until tested on eval board
#	gpioset gpiochip0 74=0
#	gpioset gpiochip0 75=0
#	gpioset gpiochip0 76=0
#	gpioset gpiochip0 77=0
	sleep 0.5
#	gpioset gpiochip0 74=1
#	gpioset gpiochip0 75=1
#	gpioset gpiochip0 76=1
#	gpioset gpiochip0 77=1

	count=$((count+1))
	echo "Blinking LEDs...$count times"
done

