#!/bin/sh
# Copyright 2024 Analog Devices Inc.
# Released under MIT licence
#

PATH=/bin:/usr/sbin:/usr/bin

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Description: Modify MAC address in OTP and/or bootcfg partition"
    echo ""
    echo "Target Options:"
    echo "   --bootcfg          Write MAC to bootcfg partition"
    echo "   --otp              Write MAC to OTP memory"
    echo ""
    echo "Interface Options:"
    echo "   --eth-1g           Primary 1G ethernet mac address"
    echo "   --eth-fh0          Primary first 10/25G ethernet mac address"
    echo "   --eth-fh1          Primary second 10/25G ethernet mac address"
    echo "   --eth-1g-sec       Secondary 1G ethernet mac address"
    echo "   --eth-fh0-sec      Secondary first 10/25G ethernet mac address"
    echo "   --eth-fh1-sec      Secondary second 10/25G ethernet mac address"
	echo ""
	echo "Mac Address Format: 01:23:45:67:89:ab"
	echo ""
}

function err() {
	# print to STDERR
	>&2 echo "$1"
}

WRITE_BOOTCFG=false
WRITE_OTP=false

MAC_1G=""
MAC_FH0=""
MAC_FH1=""
MAC_1G_SEC=""
MAC_FH0_SEC=""
MAC_FH1_SEC=""

ARGS=""

# Call getopt to validate the provided input
shortopts="h"
longopts="help,bootcfg,otp,eth-1g:,eth-fh0:,eth-fh1:,eth-1g-sec:,eth-fh0-sec:,eth-fh1-sec:"
options=$(getopt -o "$shortopts" --long "$longopts" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$options"

while true; do
	case "$1" in
		--bootcfg )
			WRITE_BOOTCFG=true
			shift
			;;
		--otp )
			WRITE_OTP=true
			shift
			;;
		--eth-1g | --eth-fh0  | --eth-fh1 | --eth-1g-sec | --eth-fh0-sec  | --eth-fh1-sec )
			value=$(echo "$2" | tr '[:upper:]' '[:lower:]' | tr '-' ':')
			MAC_REGEX="^([0-9a-f]{2}:){5}[0-9a-f]{2}$"
			if [[ "$value" =~ $MAC_REGEX ]]; then
				case "$1" in
					--eth-1g )           MAC_1G=$value; ARGS="$ARGS --eth-1g $MAC_1G" ;;
					--eth-fh0 )         MAC_FH0=$value; ARGS="$ARGS --eth-fh0 $MAC_FH0" ;;
					--eth-fh1 )         MAC_FH1=$value; ARGS="$ARGS --eth-fh1 $MAC_FH1" ;;
					--eth-1g-sec )   MAC_1G_SEC=$value; ARGS="$ARGS --eth-1g-sec $MAC_1G_SEC" ;;
					--eth-fh0-sec ) MAC_FH0_SEC=$value; ARGS="$ARGS --eth-fh0-sec $MAC_FH0_SEC" ;;
					--eth-fh1-sec ) MAC_FH1_SEC=$value; ARGS="$ARGS --eth-fh1-sec $MAC_FH1_SEC" ;;
				esac
				shift 2
			else
				err "Invalid mac address: $value"
				exit 1
			fi
			;;
		-h | --help ) 
			print_usage
			exit 0
			;;
		--)
			shift
			break
			;;
	esac
done

if [ "$WRITE_BOOTCFG" = false ] && [ "$WRITE_OTP" = false ] ; then
	err "No target selected to store the MAC(s)"
	exit 1
fi

if [ "$WRITE_BOOTCFG" = true ]; then
	echo update-bootcfg.sh $ARGS
	/usr/sbin/update-bootcfg.sh $ARGS
fi

if [ "$WRITE_OTP" = true ]; then
	if [ "$MAC_1G" != "" ];      then /usr/bin/optee_app_otp_macs 1 $MAC_1G; fi
	if [ "$MAC_FH0" != "" ];     then /usr/bin/optee_app_otp_macs 2 $MAC_FH0; fi
	if [ "$MAC_FH1" != "" ];     then /usr/bin/optee_app_otp_macs 3 $MAC_FH1; fi
	if [ "$MAC_1G_SEC" != "" ];  then /usr/bin/optee_app_otp_macs 4 $MAC_1G_SEC; fi
	if [ "$MAC_FH0_SEC" != "" ]; then /usr/bin/optee_app_otp_macs 5 $MAC_FH0_SEC; fi
	if [ "$MAC_FH1_SEC" != "" ]; then /usr/bin/optee_app_otp_macs 6 $MAC_FH1_SEC; fi
fi

exit 0
