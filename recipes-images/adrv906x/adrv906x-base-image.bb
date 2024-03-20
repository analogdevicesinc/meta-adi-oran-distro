SUMMARY = "ADRV906x base sd image w/o jtag enabled"
LICENSE = "MIT"

COMPATIBLE_MACHINE:append ?= "titan-*|"

# create `adrv906x-base-image` will also create `adrv906x-base-jtag-image`
DEPENDS:append = " adrv906x-base-jtag-image"

require adrv906x-base-common.inc

ROOTFS_IMAGE_DIR ?= "${RECIPE_SYSROOT}/dm-verity"
APP_PACK_IMAGE ?= "app_pack.bin"

do_image_wic[depends] += " adrv906x-base-jtag-image:do_populate_sysroot"
