SUMMARY = "ADRV906x swupdate image for the factory reset script"
DESCRIPTION = "This recipe generates the swupdate artifact to run the factory reset script from the swupdate daemon"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate
inherit nopackages

# Recipe files
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend := "${THISDIR}/files/factory-reset-swu:"
SRC_URI = " \
    file://sw-description \
    file://factory-reset-wrapper.sh \
    file://swupdate-priv.pass \
    file://swupdate-priv.pem \
"

S = "${WORKDIR}/image"

# SWUpdate
SWUPDATE_IMAGES = ""
SWUPDATE_SRC_URI_EXCLUDE = "swupdate-priv.pass swupdate-priv.pem"
SWUPDATE_SIGNING = "RSA"
SWUPDATE_PRIVATE_KEY = "${WORKDIR}/swupdate-priv.pem"
SWUPDATE_PASSWORD_FILE = "${WORKDIR}/swupdate-priv.pass"
IMAGE_NAME = "factory-reset"
IMAGE_LINK_NAME = ""
