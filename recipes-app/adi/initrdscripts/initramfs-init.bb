SUMMARY = "initramfs init script to load rootfs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
RDEPENDS:${PN} += "initramfs-framework-base"

inherit allarch

SRC_URI = "file://init"

do_install() {
    install -d ${D}/init.d
    install -m 0755 ${WORKDIR}/init ${D}/init.d/90-init
}

PACKAGES = "initramfs-module-init"
FILES:initramfs-module-init = "/init.d/90-init"

