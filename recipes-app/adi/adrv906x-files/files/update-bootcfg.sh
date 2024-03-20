#!/bin/sh
# Copyright 2024 Analog Devices Inc.
# Released under MIT licence
#

##############################################################
# Update bootcfg script
# Updates bootcfg partition based on parameters and values
# called with this script
##############################################################

set -e

PATH=/bin:/usr/sbin:/usr/bin

DATA_BS=4
BOOT_CFG_VERSION=00000001

TMP_BOOTCFG_DTB="/tmp/bootcfg.dtb"
TMP_BOOTCFG_BIN="/tmp/bootcfg.bin"
TMP_BOOTCFG_VAL="/tmp/bootcfg_val.bin"
TMP_BOOTCFG_TXT="/tmp/bootcfg.txt"
TMP_BOOTCFG_CRC="/tmp/bootcfg_crc.bin"

# Create empty dts file if bootcfg partition is empty or there are errors writing to the device tree
create_new_dt() {
    TMP_EMPTY="/tmp/empty.dts"

    echo "/dts-v1/;" >> $TMP_EMPTY
    echo "/ {" >> $TMP_EMPTY
    echo "};" >> $TMP_EMPTY

    dtc -o $TMP_BOOTCFG_DTB -O dtb $TMP_EMPTY

    rm $TMP_EMPTY
}

# Get bootcfg partition from the current boot device
read_bootcfg_partition() {
    # Get boot mode from device tree
    BOOT_DEV_ID=$(tr -d '\0' </proc/device-tree/chosen/boot/device)

    if [ "${BOOT_DEV_ID}" = "emmc0" ]; then
        BOOT_DEV="/dev/mmcblk0"
    elif [ "${BOOT_DEV_ID}" = "sd0" ]; then
        BOOT_DEV="/dev/mmcblk1"
    elif [ "${BOOT_DEV_ID}" = "qspi0" ]; then
        BOOT_DEV="/dev/mtd"
    else
        logger "Invalid boot device ${BOOT_DEV_ID}"
        exit 1
    fi;

    # Find bootcfg partition number by name
    BOOTCFG_PART_NAME=bootcfg

    if [ "${BOOT_DEV_ID}" != "qspi0" ]
    then
        BOOTCFG_PART_NUM=$(gdisk -l $BOOT_DEV | grep " ${BOOTCFG_PART_NAME}" | tr -s " " " " | cut -d' ' -f2)
        BOOTCFG_PART=${BOOT_DEV}p${BOOTCFG_PART_NUM}
    else
        BOOTCFG_PART_NUM=$(cat /proc/mtd | grep "${BOOTCFG_PART_NAME}" | cut -d ":" -f1 | cut -b 4-)
        BOOTCFG_PART=${BOOT_DEV}${BOOTCFG_PART_NUM}
    fi

    # Get bootcfg partition
    dd if=$BOOTCFG_PART of=$TMP_BOOTCFG_BIN

    # Get size of bootcfg partition
    bootcfg_size=$(stat -c %s $TMP_BOOTCFG_BIN)

    if [ "$(tr -d '\0' < "$TMP_BOOTCFG_BIN" | wc -c)" -eq 0 ]; then
        # Create empty device tree if bootcfg partition is empty
        logger "Bootcfg partition empty, initializing bootcfg partition"
        create_new_dt
    else
        # Obtain previous crc
        dd if=$TMP_BOOTCFG_BIN of=$TMP_BOOTCFG_VAL bs=$DATA_BS count=1
        xxd -p $TMP_BOOTCFG_VAL > $TMP_BOOTCFG_TXT
        crc=$(cat $TMP_BOOTCFG_TXT)
        b0=$(echo "$crc" | cut -c7-8)
        b1=$(echo "$crc" | cut -c5-6)
        b2=$(echo "$crc" | cut -c3-4)
        b3=$(echo "$crc" | cut -c1-2)
        crc_prev=$(echo "${b0}${b1}${b2}${b3}")

        # Obtain dtb size
        dd if=$TMP_BOOTCFG_BIN of=$TMP_BOOTCFG_VAL bs=$DATA_BS skip=2 count=1
        xxd -p $TMP_BOOTCFG_VAL > $TMP_BOOTCFG_TXT
        dtb_size=$(cat $TMP_BOOTCFG_TXT)
        b0=$(echo "$dtb_size" | cut -c7-8)
        b1=$(echo "$dtb_size" | cut -c5-6)
        b2=$(echo "$dtb_size" | cut -c3-4)
        b3=$(echo "$dtb_size" | cut -c1-2)
        dtb_size=$(echo "${b0}${b1}${b2}${b3}")
        dtb_size=$(echo $((16#"$dtb_size")))

        # Obtain version number + dtb size + dtb without crc
        crc_size=$(($dtb_size + 8))
        dd if=$TMP_BOOTCFG_BIN of=$TMP_BOOTCFG_VAL bs=1 skip=4 count=$crc_size

        # Calculate crc
        crc=$(crc32 $TMP_BOOTCFG_VAL)
        crc_cur=$(echo "$crc" | cut -c1-8)

        # Compare crc values, create empty device tree if different
        if [ "$crc_cur" != "$crc_prev" ]; then
            logger "CRC mismatch, re-initializing bootcfg partition"
            create_new_dt
        else
            # Obtain version
            dd if=$TMP_BOOTCFG_BIN of=$TMP_BOOTCFG_VAL bs=$DATA_BS skip=1 count=1
            xxd -p $TMP_BOOTCFG_VAL > $TMP_BOOTCFG_TXT
            version=$(cat $TMP_BOOTCFG_TXT)
            b0=$(echo "$version" | cut -c7-8)
            b1=$(echo "$version" | cut -c5-6)
            b2=$(echo "$version" | cut -c3-4)
            b3=$(echo "$version" | cut -c1-2)
            version=$(echo "${b0}${b1}${b2}${b3}")

            # Check that version matches
            if [ $version != $BOOT_CFG_VERSION ]; then
                logger "ERROR: Incorrect version number. Expected: $BOOT_CFG_VERSION, Actual: $version"
                exit 1
            fi
            # Obtain just dtb
            dd if=$TMP_BOOTCFG_BIN of=$TMP_BOOTCFG_DTB bs=1 skip=12 count=$dtb_size
        fi

        rm $TMP_BOOTCFG_BIN
        rm $TMP_BOOTCFG_VAL
        rm $TMP_BOOTCFG_TXT
    fi
}

# Update the bootcfg partition with crc and the updated device tree blob
update_bootcfg_partition() {
    # Add bootcfg version
    b0=$(echo "$BOOT_CFG_VERSION" | cut -c7-8)
    b1=$(echo "$BOOT_CFG_VERSION" | cut -c5-6)
    b2=$(echo "$BOOT_CFG_VERSION" | cut -c3-4)
    b3=$(echo "$BOOT_CFG_VERSION" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" > $TMP_BOOTCFG_TXT

    # Calculate size of dtb and add padding to make size a multiple of 32 bits
    dtb_size=$(stat -c %s $TMP_BOOTCFG_DTB)
    rem=$(($dtb_size % $DATA_BS))
    if [ $rem != 0 ]; then
        count=$(($DATA_BS-$rem))
        dd if=/dev/zero of=$TMP_BOOTCFG_DTB bs=1 seek=$dtb_size count=$count
        dtb_size=$(($dtb_size + $count))
    fi
    dtb_size=$(printf "%08x" $dtb_size)
    b0=$(echo "$dtb_size" | cut -c7-8)
    b1=$(echo "$dtb_size" | cut -c5-6)
    b2=$(echo "$dtb_size" | cut -c3-4)
    b3=$(echo "$dtb_size" | cut -c1-2)
    echo ${b0}${b1}${b2}${b3} >> $TMP_BOOTCFG_TXT

    # Bootcfg version + dtb size
    xxd -r -p $TMP_BOOTCFG_TXT > $TMP_BOOTCFG_BIN

    # Add dtb
    dd if=$TMP_BOOTCFG_DTB of=$TMP_BOOTCFG_BIN bs=$DATA_BS seek=2

    # Calculate crc
    crc=$(crc32 $TMP_BOOTCFG_BIN)
    b0=$(echo "$crc" | cut -c7-8)
    b1=$(echo "$crc" | cut -c5-6)
    b2=$(echo "$crc" | cut -c3-4)
    b3=$(echo "$crc" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" > $TMP_BOOTCFG_TXT

    # Convert to binary
    xxd -r -p $TMP_BOOTCFG_TXT > $TMP_BOOTCFG_CRC

    # Add crc
    dd if=$TMP_BOOTCFG_BIN of=$TMP_BOOTCFG_CRC bs=$DATA_BS seek=1

    # Update partition
    updated_size=$(stat -c %s $TMP_BOOTCFG_CRC)
    if [ "$updated_size" \> "$bootcfg_size" ]; then
        logger "ERROR: Updated bootcfg is too large for partition"
        exit 1
    fi
    if [ "${BOOT_DEV_ID}" = "qspi0" ]; then
        flash_erase $BOOTCFG_PART 0 0
        flashcp $TMP_BOOTCFG_CRC $BOOTCFG_PART
    else
        dd if=$TMP_BOOTCFG_CRC of=$BOOTCFG_PART
    fi
    logger "Updated bootcfg partition"

    rm $TMP_BOOTCFG_DTB
    rm $TMP_BOOTCFG_CRC
    rm $TMP_BOOTCFG_BIN
    rm $TMP_BOOTCFG_TXT
}

print_usage() {
    echo "Usage: update-bootcfg.sh [ARGUMENT] [VALUE]"
    echo "ARGUMENT includes:"
    echo "   --clk-pll - Add/modify clk-pll entry to VALUE, can only be set to 0 (7 GHz) or 1 (11 GHz)"
    echo "   --orx-adc - Add/modify oxd-adc entry to VALUE, can only be set to 0 (3932 MHz), 1 (7864 MHz), 2 (5898 MHz), or 3 (2949 MHz)"
    echo "   -h | --help - displays this message"
}

modify_dt() {
    read_bootcfg_partition
    fdtput -t "$1" -p $TMP_BOOTCFG_DTB "$2" "$3" "$4"
    update_bootcfg_partition
}

while [ "$1" != "" ]; 
do
    case $1 in
      --clk-pll )
        shift
        clkpll="$1"
        if [ -z "$1" ]; then
            logger "No value provided for clk-pll argument"
            exit
        elif [ "$1" = "1" ] || [ "$1" = "0" ]; then
            logger "Update bootcfg partition clk-pll to $clkpll"
            modify_dt "i" "/clk-pll" "freq" "$clkpll"
        else
            logger "Invalid clk-pll value: $clkpll"
            exit
        fi
        ;;
      --orx-adc )
        shift
        orxadc="$1"
        if [ -z "$1" ]; then
            logger "No value provided for orx-adc argument"
            exit
        elif [ "$1" = "0" ] || [ "$1" = "1" ] || [ "$1" = "2" ] || [ "$1" = "3" ]; then
            logger "Update bootcfg partition orx-adc to $orxadc"
            modify_dt "i" "/orx-adc" "freq" "$orxadc"
        else
            logger "Invalid orx-adc value: $orxadc"
            exit
        fi
        ;;
      -h | --help ) 
        print_usage
        exit
        ;;
      * ) 
        logger "Invalid option: $1"
        print_usage
        exit
        ;;
    esac
    shift
done
