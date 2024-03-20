SUMMARY = "ADRV906x nor flash image with jtag enabled"
LICENSE = "MIT"

COMPATIBLE_MACHINE:append ?= "titan-*|"

RM_WORK_EXCLUDE_ITEMS += "rootfs"
require adrv906x-flash-common.inc

APP_PACK_IMAGE ?= "debug_app_pack.bin"