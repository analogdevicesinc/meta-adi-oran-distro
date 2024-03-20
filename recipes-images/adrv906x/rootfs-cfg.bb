SUMMARY = "Rootfs configuration file generation"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

DEPENDS:append = " ${DM_VERITY_IMAGE}"
do_install[depends] = " ${DM_VERITY_IMAGE}:do_image_ext4"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

STAGING_VERITY_DIR ?= "${TMPDIR}/work-shared/${MACHINE}/dm-verity"

do_install() {
    local VERITY_ENV="${STAGING_VERITY_DIR}/${DM_VERITY_IMAGE}.${DM_VERITY_IMAGE_TYPE}.verity.env"

    install -d ${D}${sysconfdir}
    install -m 644 "${VERITY_ENV}" "${D}${sysconfdir}/rootfs-cfg.env"
}

FILES:${PN} = " \
    /etc/rootfs-cfg.env \
"
