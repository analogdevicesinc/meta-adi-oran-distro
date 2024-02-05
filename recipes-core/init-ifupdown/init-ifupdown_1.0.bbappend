FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = "   file://default-interfaces \
                    file://eth2-fallback.sh"

RDEPENDS:${PN} = "bash"

do_install:prepend () {
    SYSVINIT_ENABLED="${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}"
    if [ "${SYSVINIT_ENABLED}" = "true" ]; then
        sed -i 's:ip addr add [0-9]\+\(\.[0-9]\+\)\{3\}/[0-9]\+ dev eth2 >> /dev/null:ip addr add ${ADI_CC_FALLBACK_ADDRESS} dev eth2 >> /dev/null:' ${WORKDIR}/eth2-fallback.sh
        cp ${WORKDIR}/default-interfaces ${WORKDIR}/interfaces
    fi
}

do_install:append () {
    if [ "${SYSVINIT_ENABLED}" = "true" ]; then
        install -d "${D}${sbindir}"
        install -m 755 "${WORKDIR}/eth2-fallback.sh" "${D}${sbindir}/eth2-fallback.sh"
    fi
}
