FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

do_install:append() {
    echo "${MACHINE} ${ANTI_ROLLBACK_VERSION}" > "${D}${sysconfdir}/hwrevision"
    echo "${DISTRO_VERSION}" > "${D}${sysconfdir}/sw-versions"
}

FILES:${PN}:append = " \
    ${sysconfdir}/hwrevision \
    ${sysconfdir}/sw-versions \
"
