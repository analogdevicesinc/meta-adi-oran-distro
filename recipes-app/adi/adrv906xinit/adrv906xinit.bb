DESCRIPTION = "Samana rootfs init used by initramfs script"
LICENSE = "MIT"

SRC_URI = "file://init"

LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

S = "${WORKDIR}"

do_install () {
	install -m 0755 ${S}/init ${D}/
}

FILES:${PN} = "/init"
