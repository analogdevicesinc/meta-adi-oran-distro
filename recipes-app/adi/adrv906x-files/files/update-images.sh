#!/bin/sh

PATH=/bin:/usr/sbin:/usr/bin

DEFAULT_SW_PACKAGE_FILE="/tmp/update_image.tar"

print_usage() {
	echo ""
	echo "Usage: $0 [target] [option]"
	echo ""
	echo "For example:"
	echo " $0 current   - sw update: update inactive slot partitions on the same boot media"
	echo " $0 emmc      - initial programming: update all partitions for emmc from sd card"
	echo " $0 hybrid    - initial programming: update all partitions for flash/emmc hybrid mode from sd card"
	echo " !! for systemc - no space for package extraction, please transfer all images to /data/active/update_images !!!"
	echo ""
}

unpack_package() {
	cmd="tar xf $SW_PACKAGE_FILE -C /tmp"
	echo "no enough space on systemc, please transfer all images to /data/active/update_images/ before running the script"
	echo " The script will be upgraded to extract package when we have real HW"
#	eval "$cmd"
}

find_partname() {
	local CUR_DEV_ID=$1
	local CUR_DEV=$2
	local PART_NAME=$3
	echo "$CUR_DEV_ID"
	echo "$CUR_DEV"
	echo "$PART_NAME"

	if [ "${CUR_DEV_ID}" != "qspi0" ]
	then
		PART_NUM=$(gdisk -l "$CUR_DEV" | grep " ${PART_NAME}" | tr -s " " " " | cut -d' ' -f2)
		DEV_PART=${CUR_DEV}p${PART_NUM}
	else
		PART_NUM=$(grep "${PART_NAME}" /proc/mtd | cut -d ":" -f1 | cut -b 4-)
		DEV_PART=${CUR_DEV}${PART_NUM}
	fi
	echo "$DEV_PART"
}

set_up_device_names() {
	BOOT_DEV_ID=$(cat /proc/device-tree/chosen/boot/device) 
	if [ "$INITIAL_PROGRAM_EMMC" = true ]; then
		if [ "$BOOT_DEV_ID" = "sd0" ]; then
			TARGET_DEV_ID="emmc0"
		else
			logger -s "Error: Initial programming can only be done from SD card!"
			exit 1
		fi
	elif [ "$INITIAL_PROGRAM_HYBRID" = true ]; then
		if [ "$BOOT_DEV_ID" = "sd0" ]; then
			TARGET_DEV_ID="qspi0"
		else
			logger -s "Error: Initial programming can only be done from SD card!"
			exit 1
		fi
	else
		TARGET_DEV_ID="$BOOT_DEV_ID"
	fi

	if [ "${TARGET_DEV_ID}" = "emmc0" ]; then
		BOOT_DEV="/dev/mmcblk0"
	elif [ "${TARGET_DEV_ID}" = "sd0" ]; then
		BOOT_DEV="/dev/mmcblk1"
	elif [ "${TARGET_DEV_ID}" = "qspi0" ]; then
		BOOT_DEV="/dev/mtd"
	else
		logger -s "Invalid boot device ${TARGET_DEV_ID}"
		exit 1
	fi

	# flash MTD device is defined in device tree
	FLASH_DEV_NAME="/dev/mtd0"	

	EMMC_DEV_NAME="/dev/mmcblk0"
	
	#find flash overlay device
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" nor-flash-overlay
	FLASH_DEV_NAME="$DEV_PART"
	echo "FLASH_DEV_NAME is $FLASH_DEV_NAME"

	# Find bootctrl partition number by name
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" bootctrl
	BOOTCTRL_PART_NAME="$DEV_PART"
	echo "BOOTCTRL_PART_NAME is $BOOTCTRL_PART_NAME"

	# Find boot_a partition number by name
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" boot_a
	BOOTA_PART_NAME="$DEV_PART"
	echo "BOOTA_PART_NAME is $BOOTA_PART_NAME"

	# Find boot_b partition number by name
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" boot_b
	BOOTB_PART_NAME="$DEV_PART"
	echo "BOOTB_PART_NAME is $BOOTB_PART_NAME"

	# Find fip_a partition number by name
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" fip_a
	FIPA_PART_NAME="$DEV_PART"
	echo "FIPA_PART_NAME is $FIPA_PART_NAME"

	# Find fip_b partition number by name
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" fip_b
	FIPB_PART_NAME="$DEV_PART"
	echo "FIPB_PART_NAME is $FIPB_PART_NAME"

	# Find kernel_a partition number by name
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" kernel_a
	KERNELA_PART_NAME="$DEV_PART"
	echo "KERNELA_PART_NAME is $KERNELA_PART_NAME"

	# Find kernel_b partition number by name
	find_partname "$TARGET_DEV_ID" "$BOOT_DEV" kernel_b
	KERNELB_PART_NAME="$DEV_PART"
	echo "KERNELB_PART_NAME is $KERNELB_PART_NAME"

	if [ "${TARGET_DEV_ID}" != "qspi0" ]; then
		# Find rootfs_a partition number by name
		find_partname "$TARGET_DEV_ID" "$BOOT_DEV" rootfs_a
		ROOTFSA_PART_NAME="$DEV_PART"
		echo "ROOTFSA_PART_NAME is $ROOTFSA_PART_NAME"

		# Find rootfs_b partition number by name
		find_partname "$TARGET_DEV_ID" "$BOOT_DEV" rootfs_b
		ROOTFSB_PART_NAME="$DEV_PART"
		echo "ROOTFSB_PART_NAME is $ROOTFSB_PART_NAME"

		# Find data partition number by name
		find_partname "$TARGET_DEV_ID" "$BOOT_DEV" data
		DATA_PART_NAME="$DEV_PART"
		echo "DATA_PART_NAME is $DATA_PART_NAME"
	else
		#hybrid boot mode: rootfs on emmc0
		find_partname "emmc0" "/dev/mmcblk0" rootfs_a
		ROOTFSA_PART_NAME="$DEV_PART"
		echo "ROOTFSA_PART_NAME is $ROOTFSA_PART_NAME"

		find_partname "emmc0" "/dev/mmcblk0" rootfs_b
		ROOTFSB_PART_NAME="$DEV_PART"
		echo "ROOTFSB_PART_NAME is $ROOTFSB_PART_NAME"

		# Find data partition number by name
		find_partname "emmc0" "/dev/mmcblk0" data
		DATA_PART_NAME="$DEV_PART"
		echo "DATA_PART_NAME is $DATA_PART_NAME"
	fi
}

set_up_image_names() {
	BOOT_DEV_ID=$(cat /proc/device-tree/chosen/boot/device) 
        
	IMAGE_DIR="/data/active/update_images"
	FLASH_IMG="$IMAGE_DIR/nor_flash.dat"
	EMMC_IMG="$IMAGE_DIR/emmc.dat"
	APPPACK_IMG="$IMAGE_DIR/app_pack.bin"
	BOOTCTRL_IMG="$IMAGE_DIR/bootctrl_cfg.bin"
	FIP_IMG="$IMAGE_DIR/fip.bin"

	if [ "$INITIAL_PROGRAM_EMMC" = true ]; then
		KERNEL_IMG="$IMAGE_DIR/kernel.ext4"
	elif [ "$INITIAL_PROGRAM_HYBRID" = true ]; then
		KERNEL_IMG="$IMAGE_DIR/kernel_fit.itb"
	else
		if [ "$BOOT_DEV_ID" = "qspi0" ]; then
			KERNEL_IMG="$IMAGE_DIR/kernel_fit.itb"
		else
			KERNEL_IMG="$IMAGE_DIR/kernel.ext4"
		fi
	fi

	ROOTFS_IMG="$IMAGE_DIR/rootfs_ext4.img"
	DATA_IMG="$IMAGE_DIR/data.ext4"
}

program_all_partitions() {
	echo "programming emmc...."
	cmd="dd if=$EMMC_IMG of=$EMMC_DEV_NAME"
	echo "$cmd"
	eval "$cmd"
	if [ "$INITIAL_PROGRAM_HYBRID" = true ]; then
		echo "programming flash...."
		cmd="flash_erase $FLASH_DEV_NAME 0 0"
		echo "$cmd"
		eval "$cmd"
		cmd="flashcp $FLASH_IMG $FLASH_DEV_NAME"
		echo "$cmd"
		eval "$cmd"
	fi
}

program_one_partition() {
	CUR_IMG=$1
	CUR_DEV=$2
	CUR_ON_FLASH=$3
	if [ "$CUR_ON_FLASH" = true ]; then
		cmd="flash_erase $CUR_DEV 0 0"
		echo "$cmd"
		eval "$cmd"
		cmd="flashcp $CUR_IMG $CUR_DEV"
		echo "$cmd"
		eval "$cmd"
	else
		cmd="dd if=$CUR_IMG of=$CUR_DEV"
		echo "$cmd"
		eval "$cmd"
	fi
}

program_inactive_partitions() {
	if [ "${TARGET_DEV_ID}" != "qspi0" ]; then
		ON_FLASH=false
	else
		ON_FLASH=true
	fi

	ACTIVE_TE_SLOT=$(cat /proc/device-tree/chosen/boot/te-slot)
	echo "ACTIVE_TE_SLOT: $ACTIVE_TE_SLOT"
	if [ "$ACTIVE_TE_SLOT" != a ]; then
		program_one_partition "$APPPACK_IMG" "$BOOTA_PART_NAME" "$ON_FLASH" 
	else
		program_one_partition "$APPPACK_IMG" "$BOOTB_PART_NAME" "$ON_FLASH" 
	fi

	ACTIVE_SLOT=$(cat /proc/device-tree/chosen/boot/slot)
	echo "ACTIVE_SLOT: $ACTIVE_SLOT"

	if [ "$ACTIVE_SLOT" != a ]; then
		program_one_partition "$FIP_IMG" "$FIPA_PART_NAME" "$ON_FLASH" 
		program_one_partition "$KERNEL_IMG" "$KERNELA_PART_NAME" "$ON_FLASH" 
		program_one_partition "$ROOTFS_IMG" "$ROOTFSA_PART_NAME" false 
	else
		program_one_partition "$FIP_IMG" "$FIPB_PART_NAME" "$ON_FLASH" 
		program_one_partition "$KERNEL_IMG" "$KERNELB_PART_NAME" "$ON_FLASH" 
		program_one_partition "$ROOTFS_IMG" "$ROOTFSB_PART_NAME" false 
	fi

	# update bootctrl with new active slot

	cmd="dd if=$BOOTCTRL_PART_NAME of=/tmp/bootctrl.bin"
	echo "$cmd"
	eval "$cmd"
	cmd="dd if=/tmp/bootctrl.bin of=/tmp/header.bin bs=1 count=8"
	echo "$cmd"
	eval "$cmd"

	xxd -p /tmp/header.bin > /tmp/tmp.hex

	if [ "$ACTIVE_SLOT" != a ]; then
		echo "61000000" >> /tmp/tmp.hex
	else
		echo "62000000" >> /tmp/tmp.hex
	fi

	xxd -p -r /tmp/tmp.hex > /tmp/tmp.bin
	crc=$(crc32 /tmp/tmp.bin)
	echo "crc: $crc"
	echo "${crc:6:2}${crc:4:2}${crc:2:2}${crc:0:2}" >> /tmp/tmp.hex
	xxd -r -p /tmp/tmp.hex > /tmp/new_bootctrl.bin
	program_one_partition "/tmp/new_bootctrl.bin" "$BOOTCTRL_PART_NAME" "$ON_FLASH" 
}

# program starting point
case $1 in
	emmc )
		INITIAL_PROGRAM_EMMC=true
		INITIAL_PROGRAM_HYBRID=false
		SW_UPDATE=false
	;;
	hybrid )
		INITIAL_PROGRAM_HYBRID=true
		INITIAL_PROGRAM_EMMC=false
		SW_UPDATE=false
	;;
	current )
		INITIAL_PROGRAM_HYBRID=false
		INITIAL_PROGRAM_EMMC=false
		SW_UPDATE=true
	;;
	-h | --help ) 
		print_usage
		exit
	;;
	* ) 
		echo "Invalid parameter $1"
		print_usage
		exit
	;;
esac

echo "INITIAL_PROGRAM_EMMC:   $INITIAL_PROGRAM_EMMC"
echo "INITIAL_PROGRAM_HYBRID: $INITIAL_PROGRAM_HYBRID"
echo "SW_UPDATE:              $SW_UPDATE"

if [ -z "$2" ]; then
	SW_PACKAGE_FILE=$DEFAULT_SW_PACKAGE_FILE
else
	SW_PACKAGE_FILE=$2
fi
echo "SW_PACKAGE_FILE: $SW_PACKAGE_FILE"

unpack_package
if [ "$SW_UPDATE" = true ]; then
	echo "updating current"
elif [ "$INITIAL_PROGRAM_EMMC" = true ]; then
	echo "initial programming emmc"
elif [ "$INITIAL_PROGRAM_HYBRID" = true ]; then
	echo "initial programming hybrid"
else
	logger -s "error: $0 no action"
fi
set_up_device_names
set_up_image_names
echo $APPPACK_IMG
echo $BOOTCTRL_IMG
echo $FIP_IMG
echo $KERNEL_IMG
echo $ROOTFS_IMG

if [ "$SW_UPDATE" = true ]; then
	program_inactive_partitions
	logger -s "SW updated is completed for $TARGET_DEV_ID"
elif [ "$INITIAL_PROGRAM_EMMC" = true ]; then
	program_all_partitions
	logger -s "initial programming is completed for emmc"
elif [ "$INITIAL_PROGRAM_HYBRID" = true ]; then
	program_all_partitions
	logger -s "initial programming is completed for hybrid (flash/emmc)"
fi
sync

