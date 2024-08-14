#!/bin/sh
# Copyright 2024 Analog Devices Inc.
# Released under MIT licence
#

##############################################################
# Update images script
# Burns the eMMC/QSPI images and updates the inactive slots
##############################################################

#------------------------------------------------------------------------------
# Constants
#------------------------------------------------------------------------------
PATH=/bin:/usr/sbin:/usr/bin

BOOT_DEV_ID=$(cat /proc/device-tree/chosen/boot/device | tr -d '\0') # sd0, emmc0, qspi0
EMMC_DEV_NAME="/dev/mmcblk0"
FLASH_DEV_NAME="/dev/mtd0"

ACTIVE_SLOT=$(cat /proc/device-tree/chosen/boot/slot | tr -d '\0')

IMAGE_DIR="/data/active/update_images"
EMMC_IMG="$IMAGE_DIR/mmc.dat"
FLASH_IMG="$IMAGE_DIR/nor_flash.dat"

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
print_usage() {
	echo "Usage: $0 [initemmc|inithybrid|update] <swupdate_package>"
	echo "       $0 initemmc   <swupdate_package>  - eMMC initial programming"
	echo "       $0 inithybrid <swupdate_package>  - eMMC/QSPI initial programming"
	echo "       $0 update     <swupdate_package>  - Update inactive slots from the current boot media"
}

unpack_package() {
	package=$1
	rm -rf $IMAGE_DIR
	mkdir -p $IMAGE_DIR
	echo "Unpacking $package..."
	cmd="tar xfv $package -C $IMAGE_DIR"
	eval "$cmd"
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "ERROR: Cannot uncompress $package"
		exit 1
	fi
	echo
}

find_partname() {
	boot_dev=$1
	part_name=$2
	if [ "${boot_dev}" != "/dev/mtd" ]
	then
		part_num=$(gdisk -l "$boot_dev" | grep " ${part_name}" | awk '{print $1;}')
		dev_part=${boot_dev}p${part_num}
	else
		part_num=$(grep "${part_name}" /proc/mtd | cut -d ":" -f1 | cut -b 4-)
		dev_part=${boot_dev}${part_num}
	fi
	echo $dev_part
}

set_up_device_names() {
	bootctrl_part_name=$(find_partname $boot_dev bootctrl)
	   boota_part_name=$(find_partname $boot_dev boot_a)
	   bootb_part_name=$(find_partname $boot_dev boot_b)
	    fipa_part_name=$(find_partname $boot_dev fip_a)
	    fipb_part_name=$(find_partname $boot_dev fip_b)
	 kernela_part_name=$(find_partname $boot_dev kernel_a)
	 kernelb_part_name=$(find_partname $boot_dev kernel_b)

	if [ "$BOOT_DEV_ID" != "qspi0" ]; then
		rootfsa_part_name=$(find_partname $boot_dev rootfs_a)
		rootfsb_part_name=$(find_partname $boot_dev rootfs_b)
		   data_part_name=$(find_partname $boot_dev data)
	else
		# hybrid boot mode: rootfs on emmc0
		rootfsa_part_name=$(find_partname "/dev/mmcblk0" rootfs_a)
		rootfsb_part_name=$(find_partname "/dev/mmcblk0" rootfs_b)
		   data_part_name=$(find_partname "/dev/mmcblk0" data)
	fi
}

set_up_image_names() {
	APPPACK_IMG="$IMAGE_DIR/app_pack.bin"
	BOOTCTRL_IMG="$IMAGE_DIR/bootctrl_cfg.bin"
	FIP_IMG="$IMAGE_DIR/fip.bin"
	ROOTFS_IMG="$IMAGE_DIR/rootfs.ext4.verity"
	DATA_IMG="$IMAGE_DIR/data.ext4"
	case $BOOT_DEV_ID in
		emmc0|sd0) KERNEL_IMG="$IMAGE_DIR/kernel.ext4" ;;
		qspi0)     KERNEL_IMG="$IMAGE_DIR/kernel_fit.itb" ;;
	esac
}

program_emmc() {
	cmd="dd if=$EMMC_IMG of=$EMMC_DEV_NAME >/dev/null 2>&1"
	eval "$cmd"
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "ERROR: Cannot program eMMC"
		exit 1
	fi
}

program_qspi() {
		flash_dev_name=$(find_partname /dev/mtd nor-flash-overlay)
		echo -e "\tErasing flash..."
		cmd="flash_erase $flash_dev_name 0 0 >/dev/null 2>&1"
		eval "$cmd"
		ret=$?
		if [ $ret -ne 0 ]; then
			echo "ERROR: Cannot erase flash"
			exit 1
		fi
		echo -e "\tProgramming flash..."
		cmd="flashcp $FLASH_IMG $flash_dev_name"
		eval "$cmd"
		ret=$?
		if [ $ret -ne 0 ]; then
			echo "ERROR: Cannot program flash"
			exit 1
		fi
}

program_one_partition() {
	image=$1
	partition=$2

	if [ "$(echo $partition | grep /dev/mtd)" != "" ]; then
		echo -e "\tErasing flash partition $partition..."
		cmd="flash_erase $partition 0 0"
		eval "$cmd"
		ret=$?
		if [ $ret -ne 0 ]; then
			echo "ERROR: Cannot erase flash partition $partition"
			exit 1
		fi
		echo -e "\t$(basename $image) to $partition..."
		cmd="flashcp $image $partition"
		eval "$cmd"
		ret=$?
		if [ $ret -ne 0 ]; then
			echo "ERROR: Cannot program flash partition $partition"
			exit 1
		fi
	else
		echo -e "\t$(basename $image) to $partition..."
		cmd="dd if=$image of=$partition >/dev/null 2>&1"
		eval "$cmd"
		ret=$?
		if [ $ret -ne 0 ]; then
			echo "ERROR: Cannot program mmc partition $partition"
			exit 1
		fi
	fi
}

get_app_pack_version() {
	path=$1
	# Version 0xAAaa.0xBBbb.0xCCcc is stored in the app-pack binary as:
	#  0 ...  8  9 10 11 12 13 14 15
	# xx ... bb BB aa AA xx xx cc CC
	major=$(hexdump $path -s 10 -n 2 -e '1/2 "%u\n"')
	minor=$(hexdump $path -s  8 -n 2 -e '1/2 "%u\n"')
	patch=$(hexdump $path -s 14 -n 2 -e '1/2 "%u\n"')
	echo $major.$minor.$patch
}

get_lower_version() {
	# sort from coreutils:
	# echo "$1\n$2" | sort -V | head -n 1
	# sort from busybox:
	echo -e "$1\n$2" | sort -V | head -n 1
}

version_is_lower_than() {
	if [ "$1" == "$2" ]; then return 0; fi
	if [ "$1" = "$(get_lower_version $1 $2)" ]; then return 1; else return 0; fi
}

version_is_higher_than() {
	if [ "$1" == "$2" ]; then return 0; fi
	version_is_lower_than $1 $2
	is_lower=$?
	if [ $is_lower -eq 1 ]; then return 0; else return 1; fi
}

program_app_pack() {
	APPPACK_IMG="$IMAGE_DIR/app_pack.bin"

	ACTIVE_TE_SLOT=$(cat /proc/device-tree/chosen/boot/te-slot | tr -d '\0')

	if [ "$ACTIVE_TE_SLOT" != a ]; then
		active_te_part_name="$boota_part_name"
		inactive_te_part_name="$bootb_part_name"
	else
		active_te_part_name="$bootb_part_name"
		inactive_te_part_name="$boota_part_name"
	fi

	vNew=$(get_app_pack_version $APPPACK_IMG)
	vA=$(get_app_pack_version $boota_part_name)
	vB=$(get_app_pack_version $bootb_part_name)

	echo -e "\tApp-pack versions: A:$vA  B:$vB  New:$vNew"

	if [ "$vNew" ==  "$vA" ] && [ "$vNew" ==  "$vB" ]; then
		echo -e "\tApp-pack slots up to date"
		return
	fi

	version_is_higher_than $vNew $vA; higher_than_A=$?;
	version_is_higher_than $vNew $vB; higher_than_B=$?;
	version_is_lower_than  $vNew $vA; lower_than_A=$?;
	version_is_lower_than  $vNew $vB; lower_than_B=$?;

	if [ $higher_than_A -eq 1 ] && [ $higher_than_B -eq 1 ]; then
		echo -e "\tNew version is higher or equal than both A/B versions"
		echo -e "\tReplacing inactive slot..."
		program_one_partition "$APPPACK_IMG" "$inactive_te_part_name"
	elif [ $lower_than_A -eq 1 ] && [ $lower_than_B -eq 1 ]; then
		echo -e "\tNew version is lower than both A/B versions"
		echo -e "\tReplacing both slots..."
		program_one_partition "$APPPACK_IMG" "$active_te_part_name"
		sync
		program_one_partition "$APPPACK_IMG" "$inactive_te_part_name"
	else
		echo -e "\tNew version is between A/B versions"
		echo -e "\tCopying active to inactive..."
		cmd="dd if=$active_te_part_name of=$inactive_te_part_name >/dev/null 2>&1"
		eval "$cmd"
		ret=$?
		if [ $ret -ne 0 ]; then
			echo "ERROR: Cannot copy active to inactive app-pack"
			exit 1
		fi
		sync
		echo -e "\tReplacing active slot..."
		program_one_partition "$APPPACK_IMG" "$active_te_part_name"
	fi
}

update_boot_dev() {
	case $BOOT_DEV_ID in
		emmc0) boot_dev="/dev/mmcblk0" ;;
		sd0)   boot_dev="/dev/mmcblk1" ;;
		qspi0) boot_dev="/dev/mtd" ;;
		*)
			echo "ERROR: Invalid boot device"
			exit 1
	esac

	set_up_device_names
	set_up_image_names

	if [ "$ACTIVE_SLOT" != a ]; then
		program_one_partition "$FIP_IMG" "$fipa_part_name"
		program_one_partition "$KERNEL_IMG" "$kernela_part_name"
		program_one_partition "$ROOTFS_IMG" "$rootfsa_part_name"
	else
		program_one_partition "$FIP_IMG" "$fipb_part_name"
		program_one_partition "$KERNEL_IMG" "$kernelb_part_name"
		program_one_partition "$ROOTFS_IMG" "$rootfsb_part_name"
	fi

	# Update bootctrl with new active slot

	echo
	echo "Updating active slot indication...."
	cmd="dd if=$bootctrl_part_name of=/tmp/bootctrl.bin >/dev/null 2>&1"
	eval "$cmd"
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "ERROR: Cannot dump bootctrl partition"
		exit 1
	fi
	cmd="dd if=/tmp/bootctrl.bin of=/tmp/header.bin bs=1 count=8 >/dev/null 2>&1"
	eval "$cmd"
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "ERROR: Cannot get bootctrl header"
		exit 1
	fi
	xxd -p /tmp/header.bin > /tmp/tmp.hex

	if [ "$ACTIVE_SLOT" != a ]; then
		echo "61000000" >> /tmp/tmp.hex
	else
		echo "62000000" >> /tmp/tmp.hex
	fi

	xxd -p -r /tmp/tmp.hex > /tmp/tmp.bin
	crc=$(crc32 /tmp/tmp.bin)
	echo "${crc:6:2}${crc:4:2}${crc:2:2}${crc:0:2}" >> /tmp/tmp.hex
	xxd -r -p /tmp/tmp.hex > /tmp/new_bootctrl.bin
	program_one_partition "/tmp/new_bootctrl.bin" "$bootctrl_part_name"
}

#------------------------------------------------------------------------------
# Program starting point
#------------------------------------------------------------------------------

echo "------------------------"
echo "update-images.sh"
echo "------------------------"

# Check if 2 positional parameters are provided
if [ $# -lt 2 ]; then
    print_usage
    exit 1
fi

# Get parameters
target=$1
swupdate_package=$2

# Check target and boot media
case $target in
	initemmc|inithybrid)
		if [ "$BOOT_DEV_ID" != "sd0" ]; then
			echo "ERROR: Initial emmc/qspi programming can only be done booting from SD card!"
			exit 1
		fi
		;;
	update)
		;;
	*)
		print_usage
		exit 1
		;;
esac

# Check path
if [ ! -f "$swupdate_package" ]; then
	echo "ERROR: package $swupdate_package not found!"
	exit 1
fi

# Unpack swupdate package
unpack_package $swupdate_package

# Program required target
case $target in
	initemmc)
		echo "Programming eMMC..."
		program_emmc
		;;
	inithybrid)
		echo "Programming eMMC..."
		program_emmc
		echo
		echo "Programming QSPI flash..."
		program_qspi
		;;
	update)
		echo "Updating inactive partitions..."
		update_boot_dev
		echo
		echo "Programming App-Pack..."
		program_app_pack
		;;
esac

sync

echo
exit 0
