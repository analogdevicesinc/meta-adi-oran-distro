SUMMARY = "ADRV906x base sd image"
LICENSE = "MIT"

# create `adrv906x-base-image` will also create `adrv906x-flash-image`
DEPENDS:append = " adrv906x-flash-image"

require adrv906x-base-common.inc

ROOTFS_IMAGE_DIR ?= "${IMGDEPLOYDIR}"
APP_PACK_IMAGE ?= "app_pack.bin"
