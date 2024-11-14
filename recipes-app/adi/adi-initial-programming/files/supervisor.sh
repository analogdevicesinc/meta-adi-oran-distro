#!/usr/bin/env bash

set -e

function break_into_uboot(){
	# Send a character repeatedly to break into U-boot interactive command prompt
	uart_id=$1
	while true; do
	sleep 0.1
	echo 1 > "$uart_id"
	done
}

function remove_broken_files(){
	local temp_folder=$1
	local tftp_folder=$2
	pushd "$tftp_folder"  > /dev/null || exit 1
	# Remove the temporary files if left over from a previous run that was interrupt before they could be removed
	rm -f output.txt
	rm -frd "$temp_folder"
	popd > /dev/null || exit 1
}

function create_tftp_files(){
	local burn_emmc=$1
	local burn_norflash=$2
	local tftp_folder=$3
	local tftp_file_override=$4
	local temp_folder=$5

	for i in 0 1; do
	# Get the current device to split the files for
	if [[ "$i" -eq 0 ]] 
	then
		if [[ "$burn_emmc" -eq 1 ]] 
		then
			original_file=mmc.dat
			split_file=mmc-
		else 
			continue
		fi
	else
		if [[ "$burn_norflash" -eq 1 ]]
		then
			original_file=nor_flash.dat
			split_file=nor_flash-
		else
			break
		fi
	fi

	pushd "$tftp_folder"  > /dev/null || exit 1
	# If we already have files in the tftp folder, don't resplit and recopy unless user explicitly states they want to replace the files in the TFTP folder
	if [[ $(find . -maxdepth 1 -name "$split_file*" | wc -l) -eq 0 ]] || [[ "$tftp_file_override" -eq 1 ]]
	then
		echo "Splitting files and populating tftp folder"

		 # Calculate the checksum of the original file
		original_checksum=$(crc32 "$original_file")
		echo "Original file checksum: $original_checksum"

		# Make a temporary directory for storing split files while we calculate the CRCs
		mkdir -p ./"$temp_folder"
		dd if="$original_file" of="$temp_folder/$original_file" bs=1M
		# Split the original file into 256 MB parts, with the pattern of mmc0,mmc1,... or nor_flash0,nor_flash1,...
		pushd "$temp_folder"  > /dev/null || exit 1
		split -d -a 3 -b 256M $original_file $split_file

		# Concatenate the split files back together
    	cat "$split_file"* > concatenated_file

		# Calculate the checksum of the concatenated file
		concatenated_checksum=$(crc32 concatenated_file)
		echo "Concatenated file checksum: $concatenated_checksum"

		# Verify the integrity of the split files
		if [[ "$original_checksum" == "$concatenated_checksum" ]]; then
			echo "Integrity check passed: The split files are identical to the original file."
			rm -f concatenated_file
		else
			echo "Integrity check failed: The split files are not identical to the original file."
			exit 1
		fi

		# Calculate the CRC32 for each file, which will be verified by U-boot after the transfer
		for j in *; do
		printf "%b" "$(crc32 "$j" | sed -e 's/../\\x&/g')" > "$j"-checksum
		done

		# Copy the files into the tftp server folder and remove local copy
		for j in *; do
		cp "$j" "$3"
		rm "$j"
		done
		# Remove the temporary folder
		popd > /dev/null || exit 1
		rm -d "$temp_folder"
	else
		echo Files already in tftp folder, skipping the split and copy
	fi
	done
}

function open_uboot_prompt(){
	local uart_id=$1
	local uboot_prompt_str=$2
	local retcode=0
	# Open the UART port once the device shows up in Linux
	until exec 3<"$uart_id"; do sleep 1; done
	for i in $(seq 1 30); do
		stty -F "$uart_id" 115200 raw -parenb -parodd -cmspar cs8 hupcl -cstopb cread clocal -crtscts \
		ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon -ixoff -iuclc -ixany -imaxbel -iutf8 \
		-opost -olcuc -ocrnl -onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0 \
		-isig -icanon -iexten -echo -echoe -echok -echonl -noflsh -xcase -tostop -echoprt -echoctl -echoke -flusho -extproc || retcode=$?
		if [ $retcode -eq 0 ]
		then
			break
		fi
		sleep 1
	done

	# Wait until we actually start seeing data come from the port so we don't flood the UART with wasted characters
	input=
	while [[ "$input" == "" ]]; do
		read -r -t .1 -u 3 input
	done

	found=0
	# Search for the autoboot message, then send a character to stop the boot and drop into U-boot interactive mode
	break_into_uboot "$uart_id" &
	echo "Attempting to break into U-boot"
	while [[ found -ne 1 ]]; do
		read -r -t .1 -u 3 line
	if echo "$line" | grep -q "$uboot_prompt_str"
	then  
		echo Broke into UBoot prompt
		found=1
		pkill -P $$
	fi
	done

	return $retcode
}

function start_uboot_programming(){
	local uart_id=$1
	local server_ip=$2
	local ip_addr=$3
	local burn_emmc=$4
	local burn_norflash=$5
	local tftp_folder=$6
	local tftp_port=$7
	# Set the number of files 
	pushd "$tftp_folder"  > /dev/null || exit 1
	num_emmc_files=$(find . -maxdepth 1 -name "mmc-[0-9][0-9][0-9]" | wc -l)
	num_nor_flash_files=$(find . -maxdepth 1 -name "nor_flash-[0-9][0-9][0-9]" | wc -l)
	popd > /dev/null || exit 1

	# Convert decimal to hex since U-boot expects hex values for numeric environment variables
    num_emmc_files_hex=$(printf '%x' "$num_emmc_files")
    num_nor_flash_files_hex=$(printf '%x' "$num_nor_flash_files")

	# Flush out any remaining characters left over from trying to break in so they don't smash the first command of the environment variables
	sleep 5
	echo 1 >> "$uart_id"
	sleep 1
	# Set the environment variables for U-boot, sleep in between to give time for U-boot to execute command
	echo setenv serverip "$server_ip" >> "$uart_id"
	sleep 1
	echo setenv ipaddr "$ip_addr" >> "$uart_id"
	sleep 1
	echo setenv burnemmc "$burn_emmc" >> "$uart_id"
	sleep 1
	echo setenv burnnorflash "$burn_norflash" >> "$uart_id"
	sleep 1
	echo setenv numemmcfiles "$num_emmc_files_hex" >> "$uart_id"
	sleep 1
	echo setenv numnorflashfiles "$num_nor_flash_files_hex" >> "$uart_id"
	sleep 1
	echo setenv tftpdstp "$tftp_port" >> "$uart_id"
	sleep 5

	# Call the programming command
	echo Calling programming command
	echo run initialprogrammingcommand >> "$uart_id"
	sleep 1
}

function wait_for_programming(){
	local uart_id=$1
	local retcode=0
	# Wait for U-boot to confirm pass or fail of the programming sequence
	echo Waiting for output of programming sequence
	cat -v "$uart_id" >> output.txt &
	while true; do
		if grep -q "MMC PROBE FAILURE" output.txt
		then
			echo Failed to probe the eMMC, check MMC entry in device tree.
			retcode=1
			break
		fi

		if grep -q "SF PROBE FAILURE" output.txt
		then
			echo Failed to probe the SPI Flash, check SPI Flash entry in device tree.
			retcode=1
			break
		fi

		if grep -q "PROGRAMMING SUCCESS" output.txt
		then
			echo Programming sequence succeeded.
			break
		fi

		if grep -q "PROGRAMMING FAILURE" output.txt
		then
			echo Programming sequence failure.
			retcode=1
			break
		fi
		done

	# Kill the background process and remove the output file so we don't mess up future runs
	pkill -P $$
	rm output.txt

	return $retcode
}

function usage(){
	echo "Usage: $0 [options] uart_id ip_addr"
	echo
	echo "Options:"
	echo
	echo "  -h --help       Show this help and exit."
	echo
	echo "  -c --config     Define the path for the config file for this tool"
	echo
	echo "Arguments:"
	echo
	echo "  uart_id"
	echo "    UART device name"
	echo "  ip_addr"
	echo "    IP address for board to use during tftp transfer"
	echo
}

function err() {
	# print to STDERR
	>&2 echo "$1"
}

function main {
	local retcode
	local temp_folder=tmp
	local uart_id
	local ip_addr
	local shortopts="h,c:"
	local longopts="help,config:"
	local opts
	local configure_file
	opts=$(getopt -o "$shortopts" --long "$longopts" -- "$@")
	eval set -- "$opts"

	# shellcheck source-path=SCRIPTDIR
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

	if [[ $# -lt 1 ]]
	then
		err "Error: Missing argument 'uart_id'."
		echo && usage
		exit 1
	fi

	uart_id=$(realpath "$1")
	shift

	if [[ $# -lt 1 ]]
	then
		err "Error: Missing argument 'ip_addr'."
		echo && usage
		exit 1
	fi

	ip_addr=$1
	shift

	if [[ $# -gt 0 ]]
	then
		err "Error: Unexpected argument '$1'."
		echo && usage
		exit 1
	fi

	if [ -f "$configure_file" ]; then
		echo "Using configuration file: $configure_file"
		source "$configure_file"
	elif [ -f "$HOME/.config/initialprogramming/configure.env" ]; then
		echo "Using configuration file: ~/.config/initialprogramming/configure.env"
		source "$HOME/.config/initialprogramming/configure.env"
	elif [ -f "$OECORE_NATIVE_SYSROOT/etc/initialprogramming/configure.env" ]; then
		echo "Using configuration file: $OECORE_NATIVE_SYSROOT/etc/initialprogramming/configure.env"
		source "$OECORE_NATIVE_SYSROOT/etc/initialprogramming/configure.env"
	else
		echo "No configuration file found."
		exit 1
	fi

	remove_broken_files "$temp_folder" "$ADI_TFTP_FOLDER"
	create_tftp_files "$ADI_BURN_EMMC" "$ADI_BURN_NOR_FLASH" "$ADI_TFTP_FOLDER" "$ADI_TFTP_FILE_OVERRIDE" "$temp_folder"
	open_uboot_prompt "$uart_id" "$ADI_UBOOT_PROMPT_STR" || retcode=1
	if [[ $retcode -ne 0 ]]
	then
		echo Issue setting up serial port with stty.
		return $retcode
	fi
	start_uboot_programming "$uart_id" "$ADI_SERVER_IP" "$ip_addr" "$ADI_BURN_EMMC" "$ADI_BURN_NOR_FLASH" "$ADI_TFTP_FOLDER" "$ADI_TFTP_PORT"
	wait_for_programming "$uart_id" || retcode=1
	if [[ $retcode -ne 0 ]]
	then
		echo Error with programming, check terminal for details.
		return $retcode
	fi

	return $retcode

}

main "$@"
