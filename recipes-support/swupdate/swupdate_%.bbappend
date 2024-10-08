FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI:append = " file://swupdate.cfg"

do_install:append() {
    install -m 644 "${WORKDIR}/swupdate.cfg" "${D}${sysconfdir}/swupdate.cfg"
    echo "${MACHINE} ${ANTI_ROLLBACK_VERSION}" > "${D}${sysconfdir}/hwrevision"
    echo "${DISTRO_VERSION}" > "${D}${sysconfdir}/sw-versions"
}

FILES:${PN}:append = " \
    ${sysconfdir}/hwrevision \
    ${sysconfdir}/sw-versions \
    ${sysconfdir}/swupdate.cfg \
"
