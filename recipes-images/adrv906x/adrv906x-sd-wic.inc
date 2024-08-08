SUMMARY = "ADRV906x wic image creation for sd"

require adrv906x-wic-common.inc

def get_adjusted_part_size(d, part_size_var, adjustment, units):
    size = d.getVar(part_size_var)
    try:
        size = int(size)
    except ValueError:
        size = 0
    return f'{size + adjustment}{units}'

BOOTCTRL_PART_SIZE ?= "64K"
BOOTCFG_PART_SIZE ?= "64K"
BOOT_PART_SIZE ?= "256K"
FIP_PART_SIZE ?= "4M"
KERNEL_PART_SIZE ?= "48M"
# rootfs needs an extra ~32M for dm-verity headers/checksums
ROOTFS_PART_SIZE := "${@get_adjusted_part_size(d, 'IMAGE_ROOTFS_SIZE', 32768, 'K')}"
DATA_PART_SIZE ?= "20M"

PART_ALIGNMENT ?= "1024"

# 4G total image size
IMAGE_TOTAL_SIZE ?= "4294967296"
