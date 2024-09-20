SUMMARY = "ADRV906x swupdate image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

DEPENDS:append = " ${DM_VERITY_IMAGE}"
do_swuimage[depends] = "${DM_VERITY_IMAGE}:do_image_complete"

inherit swupdate
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://sw-description \
"
SWUPDATE_IMAGES = "${DM_VERITY_IMAGE}-${MACHINE}.ext4.verity"
