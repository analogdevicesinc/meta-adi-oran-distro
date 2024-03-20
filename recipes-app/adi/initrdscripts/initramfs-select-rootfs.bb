SUMMARY = "root fs select module for the modular initramfs system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
RDEPENDS:${PN} += "initramfs-framework-base"

inherit allarch

SRC_URI = "file://selectrootfs"


do_install() {
    install -d ${D}/init.d
    install -m 0755 ${WORKDIR}/selectrootfs ${D}/init.d/90-selectrootfs
}

PACKAGES = "initramfs-module-select-rootfs"
FILES:initramfs-module-select-rootfs= "/init.d/90-selectrootfs"

