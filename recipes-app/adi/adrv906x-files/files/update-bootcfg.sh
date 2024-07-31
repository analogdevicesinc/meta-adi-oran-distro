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

    echo "/dts-v1/;" >> "$TMP_EMPTY"
    echo "/ {" >> "$TMP_EMPTY"
    echo "};" >> "$TMP_EMPTY"

    dtc -o "$TMP_BOOTCFG_DTB" -O dtb "$TMP_EMPTY"

    rm "$TMP_EMPTY"
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
        BOOTCFG_PART_NUM=$(for part in $(ls ${BOOT_DEV}p*); do udevadm info "$part" | grep -q "PARTNAME=$BOOTCFG_PART_NAME" && echo "$part" && break; done)
        BOOTCFG_PART_NUM=${BOOTCFG_PART_NUM#*${BOOT_DEV}p}
        BOOTCFG_PART="${BOOT_DEV}p${BOOTCFG_PART_NUM}"
    else
        BOOTCFG_PART_NUM=$(cat /proc/mtd | grep "${BOOTCFG_PART_NAME}" | cut -d ":" -f1 | cut -b 4-)
        BOOTCFG_PART="${BOOT_DEV}${BOOTCFG_PART_NUM}"
    fi

    # Get bootcfg partition
    dd if="$BOOTCFG_PART" of="$TMP_BOOTCFG_BIN" 2> /dev/null

    # Get size of bootcfg partition
    bootcfg_size=$(stat -c %s "$TMP_BOOTCFG_BIN")

    if [ "$(tr -d '\0' < "$TMP_BOOTCFG_BIN" | wc -c)" -eq 0 ]; then
        # Create empty device tree if bootcfg partition is empty
        logger "Bootcfg partition empty, initializing bootcfg partition"
        create_new_dt
    else
        # Obtain previous crc
        dd if="$TMP_BOOTCFG_BIN" of="$TMP_BOOTCFG_VAL" bs="$DATA_BS" count=1 2> /dev/null
        xxd -p "$TMP_BOOTCFG_VAL" > "$TMP_BOOTCFG_TXT"
        crc=$(cat "$TMP_BOOTCFG_TXT")
        b0=$(echo "$crc" | cut -c7-8)
        b1=$(echo "$crc" | cut -c5-6)
        b2=$(echo "$crc" | cut -c3-4)
        b3=$(echo "$crc" | cut -c1-2)
        crc_prev=$(echo "${b0}${b1}${b2}${b3}")

        # Obtain dtb size
        dd if="$TMP_BOOTCFG_BIN" of="$TMP_BOOTCFG_VAL" bs="$DATA_BS" skip=2 count=1 2> /dev/null
        xxd -p "$TMP_BOOTCFG_VAL" > "$TMP_BOOTCFG_TXT"
        dtb_size=$(cat "$TMP_BOOTCFG_TXT")
        b0=$(echo "$dtb_size" | cut -c7-8)
        b1=$(echo "$dtb_size" | cut -c5-6)
        b2=$(echo "$dtb_size" | cut -c3-4)
        b3=$(echo "$dtb_size" | cut -c1-2)
        dtb_size=$(echo "${b0}${b1}${b2}${b3}")
        dtb_size=$(echo $((16#$dtb_size)))

        if [ "$dtb_size" -eq 0 ]; then
            # Create empty device tree if bootcfg partition is empty
            logger "Bootcfg partition empty, initializing bootcfg partition"
            create_new_dt
            return
        fi

        # Obtain version number + dtb size + dtb without crc
        crc_size=$(($dtb_size + 8))
        dd if="$TMP_BOOTCFG_BIN" of="$TMP_BOOTCFG_VAL" bs=1 skip=4 count="$crc_size" 2> /dev/null

        # Calculate crc
        crc=$(crc32 "$TMP_BOOTCFG_VAL")
        crc_cur=$(echo "$crc" | cut -c1-8)

        # Compare crc values, create empty device tree if different
        if [ "$crc_cur" != "$crc_prev" ]; then
            logger "CRC mismatch, re-initializing bootcfg partition"
            create_new_dt
        else
            # Obtain version
            dd if="$TMP_BOOTCFG_BIN" of="$TMP_BOOTCFG_VAL" bs="$DATA_BS" skip=1 count=1 2> /dev/null
            xxd -p "$TMP_BOOTCFG_VAL" > "$TMP_BOOTCFG_TXT"
            version=$(cat "$TMP_BOOTCFG_TXT")
            b0=$(echo "$version" | cut -c7-8)
            b1=$(echo "$version" | cut -c5-6)
            b2=$(echo "$version" | cut -c3-4)
            b3=$(echo "$version" | cut -c1-2)
            version=$(echo "${b0}${b1}${b2}${b3}")

            # Check that version matches
            if [ "$version" != "$BOOT_CFG_VERSION" ]; then
                logger "ERROR: Incorrect version number. Expected: $BOOT_CFG_VERSION, Actual: $version"
                exit 1
            fi
            # Obtain just dtb
            dd if="$TMP_BOOTCFG_BIN" of="$TMP_BOOTCFG_DTB" bs=1 skip=12 count="$dtb_size" 2> /dev/null
        fi

        rm "$TMP_BOOTCFG_BIN"
        rm "$TMP_BOOTCFG_VAL"
        rm "$TMP_BOOTCFG_TXT"
    fi
}

# Update the bootcfg partition with crc and the updated device tree blob
update_bootcfg_partition() {
    # Add bootcfg version
    b0=$(echo "$BOOT_CFG_VERSION" | cut -c7-8)
    b1=$(echo "$BOOT_CFG_VERSION" | cut -c5-6)
    b2=$(echo "$BOOT_CFG_VERSION" | cut -c3-4)
    b3=$(echo "$BOOT_CFG_VERSION" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" > "$TMP_BOOTCFG_TXT"

    # Calculate size of dtb and add padding to make size a multiple of 32 bits
    dtb_size=$(stat -c %s "$TMP_BOOTCFG_DTB")
    rem=$(("$dtb_size" % "$DATA_BS"))
    if [ $rem != 0 ]; then
        count=$(($DATA_BS-$rem))
        dd if=/dev/zero of="$TMP_BOOTCFG_DTB" bs=1 seek="$dtb_size" count="$count" 2> /dev/null
        dtb_size=$(($dtb_size + $count))
    fi
    dtb_size=$(printf "%08x" "$dtb_size")
    b0=$(echo "$dtb_size" | cut -c7-8)
    b1=$(echo "$dtb_size" | cut -c5-6)
    b2=$(echo "$dtb_size" | cut -c3-4)
    b3=$(echo "$dtb_size" | cut -c1-2)
    echo ${b0}${b1}${b2}${b3} >> "$TMP_BOOTCFG_TXT"

    # Bootcfg version + dtb size
    xxd -r -p "$TMP_BOOTCFG_TXT" > "$TMP_BOOTCFG_BIN"

    # Add dtb
    dd if="$TMP_BOOTCFG_DTB" of="$TMP_BOOTCFG_BIN" bs="$DATA_BS" seek=2 2> /dev/null

    # Calculate crc
    crc=$(crc32 "$TMP_BOOTCFG_BIN")
    b0=$(echo "$crc" | cut -c7-8)
    b1=$(echo "$crc" | cut -c5-6)
    b2=$(echo "$crc" | cut -c3-4)
    b3=$(echo "$crc" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" > "$TMP_BOOTCFG_TXT"

    # Convert to binary
    xxd -r -p "$TMP_BOOTCFG_TXT" > "$TMP_BOOTCFG_CRC"

    # Add crc
    dd if="$TMP_BOOTCFG_BIN" of="$TMP_BOOTCFG_CRC" bs="$DATA_BS" seek=1 2> /dev/null

    # Update partition
    updated_size=$(stat -c %s "$TMP_BOOTCFG_CRC")
    if [ "$updated_size" \> "$bootcfg_size" ]; then
        logger "ERROR: Updated bootcfg is too large for partition"
        exit 1
    fi
    if [ "${BOOT_DEV_ID}" = "qspi0" ]; then
        flash_erase "$BOOTCFG_PART" 0 0
        flashcp "$TMP_BOOTCFG_CRC" "$BOOTCFG_PART"
    else
        dd if="$TMP_BOOTCFG_CRC" of="$BOOTCFG_PART" 2> /dev/null
    fi
    logger "Updated bootcfg partition"

    rm "$TMP_BOOTCFG_DTB"
    rm "$TMP_BOOTCFG_CRC"
    rm "$TMP_BOOTCFG_BIN"
    rm "$TMP_BOOTCFG_TXT"
}

print_usage() {
    echo "Usage: update-bootcfg.sh [<parameter> [<value>]]"
    echo ""
    echo "Description: Add or modify a parameter value, or read it if no value is provided" 
    echo ""
    echo "<parameter>:"
    echo "   --clk-pll          PLL clock selection: 0 (7 GHz) or 1 (11 GHz)"
    echo "   --orx-adc          ORX adc clock selection: 0 (3932 MHz), 1 (7864 MHz), 2 (5898 MHz), or 3 (2949 MHz)"
    echo "   --eth-1g           Primary 1G ethernet mac address. Format: ab:cd:ef:gh:ij:kl"
    echo "   --eth-fh0          Primary first 10/25G ethernet mac address"
    echo "   --eth-fh1          Primary second 10/25G ethernet mac address"
    echo "   --eth-1g-sec       Secondary 1G ethernet mac address"
    echo "   --eth-fh0-sec      Secondary first 10/25G ethernet mac address"
    echo "   --eth-fh1-sec      Secondary second 10/25G ethernet mac address"
    echo "   --factory-reset    Factory reset selection: 1 to enable"
    echo "   --help | -h        Display this message"
}

modify_dt() {
    read_bootcfg_partition
    fdtput -t "$1" -p $TMP_BOOTCFG_DTB "$2" "$3" $4
    update_bootcfg_partition
}

read_dt() {
    read_bootcfg_partition
    fdtget -t $1 "$TMP_BOOTCFG_DTB" "$2" "$3"
    rm "$TMP_BOOTCFG_DTB"
}

while [ "$1" != "" ]; 
do
    # Check if there is a value
    value="$2"
    if [ "${value:0:2}" = "--" ]; then
        # Next field is a new command, not a value
        value=""
    fi

    case "$1" in
      --clk-pll )
        if [ -z "$value" ]; then
            value=$(read_dt "i" "/clk-pll" "freq")
            echo "READ clk-pll: $value"
            logger "Read bootcfg partition clk-pll freq: $value"
        elif [ "$value" = "1" ] || [ "$value" = "0" ]; then
            logger "Update bootcfg partition clk-pll to $value"
            modify_dt "i" "/clk-pll" "freq" "$value"
            shift
        else
            logger "Invalid clk-pll value: $value"
            exit
        fi
        ;;
      --orx-adc )
        if [ -z "$value" ]; then
            value=$(read_dt "i" "/orx-adc" "freq")
            echo "READ orx-adc: $value"
            logger "Read bootcfg partition orx-adc freq: $value"
        elif [ "$value" = "0" ] || [ "$value" = "1" ] || [ "$value" = "2" ] || [ "$value" = "3" ]; then
            logger "Update bootcfg partition orx-adc to $value"
            modify_dt "i" "/orx-adc" "freq" "$value"
            shift
        else
            logger "Invalid orx-adc value: $value"
            exit
        fi
        ;;
      --eth-1g | --eth-fh0  | --eth-fh1 | --eth-1g-sec | --eth-fh0-sec  | --eth-fh1-sec )
        MAC_REGEX="^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$"
        declare -A node_name=(
              ['--eth-1g']='/emac1'
              ['--eth-fh0']='/emac2'
              ['--eth-fh1']='/emac3'
              ['--eth-1g-sec']='/emac4'
              ['--eth-fh0-sec']='/emac5'
              ['--eth-fh1-sec']='/emac6')

        param=${node_name[$1]}
	iface_name=$(echo $1 | sed -e 's/--//g')

        if [ -z "$value" ]; then
            value=$(read_dt "bx" $param "mac-address")
            mac_format_value=$(echo $value | sed 's/\([0-9]\) /\1:/g') # xx xx xx xx xx xx -> xx:xx:xx:xx:xx:xx
            echo "READ $iface_name: $mac_format_value"
            logger "Read $iface_name mac address: $mac_format_value"
        elif [[ "$value" =~ $MAC_REGEX ]]; then
            mac=$(echo $value | sed -e 's/:/ /g')   # 00:11:22:33:44:55 --> 00 11 22 33 44 55
            logger "$iface_name mac address set to $value"
            modify_dt "bx" $param "mac-address" "$mac"
            shift
        else
            logger "Invalid $iface_name mac address: $value" | sed -e 's/--//g'
            exit
        fi
        ;;
      --factory-reset )
        if [ -z "$value" ]; then
            value=$(read_dt "i" "/factory-reset" "status")
            echo "READ factory-reset: $value"
            logger "Read bootcfg partition factory-reset status: $value"
        elif [ "$value" = "1" ]; then
            logger "Update bootcfg partition factory-reset to $value"
            modify_dt "i" "/factory-reset" "status" "$value"
            shift
        else
            logger "Invalid factory-reset status: $value"
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
