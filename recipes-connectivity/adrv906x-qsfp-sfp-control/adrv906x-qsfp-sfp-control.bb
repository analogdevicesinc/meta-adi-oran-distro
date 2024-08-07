SUMMARY = "Enable QSFP/SFP when Linux reaches run level 5 (network service ready)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

COMPATIBLE_MACHINE = "denali|titan-4"

SRC_URI:denali = "file://qsfp-enable"
SRC_URI:titan-4 = "file://sfp-enable-titan-4"

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = ""
INITSCRIPT_NAME:denali = "qsfp-enable"
INITSCRIPT_NAME:titan-4 = "sfp-enable"

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
}
do_install:append:denali() {
    install -m 755      "${S}/qsfp-enable"              "${D}${sysconfdir}/init.d/qsfp-enable"
}
do_install:append:titan-4() {
    install -m 755      "${S}/sfp-enable-titan-4"       "${D}${sysconfdir}/init.d/sfp-enable"
}

FILES:${PN} = "${sysconfdir}/init.d"
FILES:${PN}:append:denali = " ${sysconfdir}/init.d/qsfp-enable"
FILES:${PN}:append:titan-4 = " ${sysconfdir}/init.d/sfp-enable"