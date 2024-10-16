FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI:append = " file://swupdate.cfg file://swupdate.pem"

HWREV ?= "A"

do_install:append() {
    install -m 644 "${WORKDIR}/swupdate.cfg" "${D}${sysconfdir}/swupdate.cfg"
    install -m 644 "${WORKDIR}/swupdate.pem" "${D}${sysconfdir}/swupdate.pem"
    echo "${MACHINE} ${HWREV}" > "${D}${sysconfdir}/hwrevision"
    echo "${DISTRO_VERSION}" > "${D}${sysconfdir}/sw-versions"
}

FILES:${PN}:append = " \
    ${sysconfdir}/hwrevision \
    ${sysconfdir}/sw-versions \
    ${sysconfdir}/swupdate.cfg \
    ${sysconfdir}/swupdate.pem \
"
