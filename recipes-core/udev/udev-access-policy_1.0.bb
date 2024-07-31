SUMMARY = "Device access control rules for udev"
DESCRIPTION = "Device access control rules for udev"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
        file://access-policy.rules \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/access-policy.rules ${D}${sysconfdir}/udev/rules.d/access-policy.rules
}

RDEPENDS:${PN} = "udev"

SRC_URI:append:denali = "file://access-policy-denali.rules"
do_install:append:denali() {
    install -m 0644 ${WORKDIR}/access-policy-denali.rules ${D}${sysconfdir}/udev/rules.d/
}

SRC_URI:append:titan = "file://access-policy-titan.rules"
do_install:append:titan() {
    install -m 0644 ${WORKDIR}/access-policy-titan.rules ${D}${sysconfdir}/udev/rules.d/
}
