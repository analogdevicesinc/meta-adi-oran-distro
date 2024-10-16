SUMMARY = "ADRV906x swupdate image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

DEPENDS:append = " ${DM_VERITY_IMAGE}"
do_swuimage[depends] = "${DM_VERITY_IMAGE}:do_image_complete"

require adrv906x-partitions.inc
APP_PACK_IMAGE ?= "app_pack.bin"
HWREV ?= "A"

inherit swupdate
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://sw-description \
    file://update-slot.sh \
    file://swupdate-priv.pass \
    file://swupdate-priv.pem \
"
SWUPDATE_SRC_URI_EXCLUDE = "swupdate-priv.pass swupdate-priv.pem"
SWUPDATE_SIGNING = "RSA"
SWUPDATE_PRIVATE_KEY = "${WORKDIR}/swupdate-priv.pem"
SWUPDATE_PASSWORD_FILE = "${WORKDIR}/swupdate-priv.pass"
SWUPDATE_IMAGES = " \
    ${APP_PACK_IMAGE} \
    fip.bin \
    fitImage-${INITRAMFS_IMAGE}-${MACHINE}-${MACHINE} \
    ${DM_VERITY_IMAGE}-${MACHINE}.ext4.verity.gz \
"
