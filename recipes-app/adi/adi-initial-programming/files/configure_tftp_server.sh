#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR
function usage(){
	echo "Usage: $0 [options]"
	echo
	echo "Options:"
	echo
	echo "  -h --help       Show this help and exit."
	echo
	echo "  -c --config     Define the path for the config file for this tool"
	echo
}

function main {
	local shortopts="h,c:"
	local longopts="help,config:"
	local opts
	local configure_file
	opts=$(getopt -o "$shortopts" --long "$longopts" -- "$@")
	eval set -- "$opts"

	while :
	do
	case "$1" in
		-h | --help)
			usage; exit 0 ;;
		-c | --config)
			configure_file=$(realpath "$2")
			shift 2 ;;
		--)
			shift
			break ;;
		*)
			err "Error: Unrecognized option '$1'"
			echo && usage
			exit 1 ;;
	esac
	done

	# Make sure script is being run as root for installation purposes and modifying file permissions
	if [[ "$EUID" -ne 0 ]]
		then echo "Please run as root"
		exit
	fi

	if [ -f "$configure_file" ]; then
		echo "Using configuration file: $configure_file"
		source "$configure_file"
	elif [ -f "/home/$SUDO_USER/.config/initialprogramming/configure.env" ]; then
		echo "Using configuration file: ~/.config/initialprogramming/configure.env"
		source "/home/$SUDO_USER/.config/initialprogramming/configure.env"
	elif [ -f "$OECORE_NATIVE_SYSROOT/etc/initialprogramming/configure.env" ]; then
		echo "Using configuration file: $OECORE_NATIVE_SYSROOT/etc/initialprogramming/configure.env"
		source "$OECORE_NATIVE_SYSROOT/etc/initialprogramming/configure.env"
	else
		echo "No configuration file found."
		exit 1
	fi

	# Make folder for tftp files 
	mkdir -p "$ADI_TFTP_FOLDER"
	chmod -R 777 "${ADI_TFTP_FOLDER}"
	chown -R nobody "${ADI_TFTP_FOLDER}"

	echo "Starting tftp server"
	# Start tftp server and bind to port specified by user
	in.tftpd --foreground -a 0.0.0.0:"$ADI_TFTP_PORT" -s "$ADI_TFTP_FOLDER"
}

main "$@"
