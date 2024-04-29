SUMMARY = "Anti-rollback-version file for rootfs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

do_install() {
    install -d "${D}${sysconfdir}"
    echo "${ANTI_ROLLBACK_VERSION}" > "${D}${sysconfdir}/anti-rollback-version"
}

FILES:${PN} = " \
    ${sysconfdir}/anti-rollback-version \
"
