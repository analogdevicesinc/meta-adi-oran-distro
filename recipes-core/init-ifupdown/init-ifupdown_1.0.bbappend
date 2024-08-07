FILESEXTRAPATHS:prepend := "${THISDIR}/files/${MACHINE}:${THISDIR}/files:${THISDIR}"
SRC_URI:append = "   file://default-interfaces \
                    file://eth-fallback.sh"

RDEPENDS:${PN} = "bash"

do_install:prepend () {
    SYSVINIT_ENABLED="${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}"
    if [ "${SYSVINIT_ENABLED}" = "true" ]; then
        sed -i 's:post-up /usr/sbin/eth-fallback.sh eth2 [0-9]\+\(\.[0-9]\+\)\{3\}/[0-9]\+ >> /dev/null:post-up /usr/sbin/eth-fallback.sh eth2 ${ADI_CC_FALLBACK_ADDRESS} >> /dev/null:' ${WORKDIR}/default-interfaces
        cp ${WORKDIR}/default-interfaces ${WORKDIR}/interfaces
    fi
}

do_install:append () {
    if [ "${SYSVINIT_ENABLED}" = "true" ]; then
        install -d "${D}${sbindir}"
        install -m 755 "${WORKDIR}/eth-fallback.sh" "${D}${sbindir}/eth-fallback.sh"
    fi
}
