SUMMARY = "ADRV906x nor flash image w/o jtag enabled"
LICENSE = "MIT"

COMPATIBLE_MACHINE:append ?= "titan-*|"

# create `adrv906x-flash-image` will also create `adrv906x-flash-jtag-image`
DEPENDS:append = " adrv906x-flash-jtag-image"

require adrv906x-flash-common.inc

APP_PACK_IMAGE ?= "app_pack.bin"