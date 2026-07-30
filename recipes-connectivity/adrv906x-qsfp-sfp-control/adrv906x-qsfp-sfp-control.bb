SUMMARY = "Enable QSFP/SFP when Linux reaches run level 5 (network service ready)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

COMPATIBLE_MACHINE = "denali|titan-8"

SRC_URI:denali = "file://qsfp-enable-denali"
SRC_URL:titan-8 = "file://qsfp-enable-titan-8"

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = ""
INITSCRIPT_NAME:denali = "qsfp-enable"
INITSCRIPT_NAME:titan-8 = "qsfp-enable"

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
}
do_install:append:denali() {
    install -m 755      "${S}/qsfp-enable-denali"       "${D}${sysconfdir}/init.d/qsfp-enable"
}
do_install:append:titan-8() {
    install -m 755      "${S}/qsfp-enable-titan-8"      "${D}${sysconfdir}/init.d/qsfp-enable"
}

FILES:${PN} = "${sysconfdir}/init.d"
FILES:${PN}:append:denali = " ${sysconfdir}/init.d/qsfp-enable"
FILES:${PN}:append:titan-8 = " ${sysconfdir}/init.d/qsfp-enable"