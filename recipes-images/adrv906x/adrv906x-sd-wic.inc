SUMMARY = "ADRV906x wic image creation for sd"

require adrv906x-wic-common.inc

BOOTCTRL_PART_SIZE?="64K"
BOOTCFG_PART_SIZE?="64K"
BOOT_PART_SIZE?="256K"
FIP_PART_SIZE?="4M"
KERNEL_PART_SIZE?="48M"
ROOTFS_PART_SIZE="256M"
DATA_PART_SIZE?="360M"

PART_ALIGNMENT?="1024"
IMAGE_TOTAL_SIZE?="1073741824"