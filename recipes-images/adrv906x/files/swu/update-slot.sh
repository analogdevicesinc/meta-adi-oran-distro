#!/bin/sh

set -e

err() {
    >&2 echo $@;
}

get_boot_dev() {
    case $(cat /proc/device-tree/chosen/boot/device | tr -d '\0') in
        emmc0) echo "/dev/mmcblk0" ;;
        sd0)   echo "/dev/mmcblk1" ;;
        qspi0) echo "/dev/mtd" ;;
    esac
}

find_partname() {
    local boot_dev=$1
    local part_name=$2
    local part_num
    if [ "${boot_dev}" != "/dev/mtd" ]; then
        part_num=$(gdisk -l "$boot_dev" | grep " ${part_name}" | awk '{print $1;}')
        echo "${boot_dev}p${part_num}"
    else
        part_num=$(grep "${part_name}" /proc/mtd | cut -d ":" -f1 | cut -b 4-)
        echo "${boot_dev}${part_num}"
    fi
    echo $dev_part
}

program_one_partition() {
    local image=$1
    local partition=$2

    if [ "$(echo $partition | grep /dev/mtd)" != "" ]; then
        flash_erase $partition 0 0
        if [ $? -ne 0 ]; then
            err "ERROR: Cannot erase flash partition $partition"
            exit 1
        fi
        flashcp $image $partition
        if [ $? -ne 0 ]; then
            err "ERROR: Cannot program flash partition $partition"
            exit 1
        fi
    else
        dd if=$image of=$partition >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            err "ERROR: Cannot program mmc partition $partition"
            exit 1
        fi
    fi
}

main() {
    local boot_dev=$(get_boot_dev)
    local bootctrl_part_name=$(find_partname $boot_dev bootctrl)
    dd if=$bootctrl_part_name of=/tmp/bootctrl_cfg.bin >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        err "ERROR: Cannot dump bootctrl partition"
        exit 1
    fi

    dd if=/tmp/bootctrl_cfg.bin of=/tmp/bootctrl_header.bin bs=1 count=8 >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        err "ERROR: Cannot extract bootctrl header"
        exit 1
    fi

    xxd -p /tmp/bootctrl_header.bin > /tmp/bootctrl_cfg.hex
    rm /tmp/bootctrl_header.bin

    if [ "$(cat /proc/device-tree/chosen/boot/slot | tr -d '\0')" == "a" ]; then
        echo "62000000" >> /tmp/bootctrl_cfg.hex # boot from slot b
    else
        echo "61000000" >> /tmp/bootctrl_cfg.hex # boot from slot a
    fi

    xxd -p -r /tmp/bootctrl_cfg.hex > /tmp/bootctrl_tmp.bin
    crc=$(crc32 /tmp/bootctrl_tmp.bin)
    rm /tmp/bootctrl_tmp.bin
    echo "${crc:6:2}${crc:4:2}${crc:2:2}${crc:0:2}" >> /tmp/bootctrl_cfg.hex
    xxd -r -p /tmp/bootctrl_cfg.hex > /tmp/bootctrl_cfg.bin
    rm /tmp/bootctrl_cfg.hex

    program_one_partition "/tmp/bootctrl_cfg.bin" "$bootctrl_part_name"
}

main "$@"
