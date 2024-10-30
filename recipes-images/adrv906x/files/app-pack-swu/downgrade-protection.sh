#!/bin/sh

set -e

err() {
    >&2 echo $@;
}

version_cmp() {
    # returns negative if a < b
    # returns positive if a > b
    # returns 0 if a == b

    local ver_a=$1
    local ver_b=$2
    if [ "$ver_a" == "$ver_b" ]; then
        return 0
    fi
    local ver_lowest=$(echo -e "$ver_a\n$ver_b" | sort -V | head -n 1)
    if [ "$ver_lowest" == "$ver_a" ]; then
        return -1
    else
        return 1
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

main() {
    local boot_dev=$(get_boot_dev)
    local active_slot=$(cat /proc/device-tree/chosen/boot/te-slot | tr -d '\0')
    local inactive_slot
    case "$active_slot" in
        a) inactive_slot=b ;;
        b) inactive_slot=a ;;
        *) err "ERROR: Invalid active slot $active_slot"; exit 1 ;;
    esac
    local partition_active=boot_${active_slot}
    local partition_inactive=boot_${active_slot}
    local device_active=$(find_partname "$boot_dev" "$partition_active")
    local device_inactive=$(find_partname "$boot_dev" "$partition_inactive")
    local verion_active=$(get_app_pack_version "$device_active")
    local verion_inactive=$(get_app_pack_version "$device_inactive")
    version_cmp "$version_active" "$version_inactive"
    if [ $? -gte 0 ]; then
        # TE loads the newest app-pack, rather than the slot configured in bootctrl
        # if the active slot's app-pack is newer than the one we just installed,
        # we need to downgrade the app-pack in the active slot to match
        dd if="${device_inactive}" of="${device_active}" >/dev/null 2>&1
    fi
}

main "$@"
