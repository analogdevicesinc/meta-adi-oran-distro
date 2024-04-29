FILESEXTRAPATHS:prepend := "${THISDIR}/files/${MACHINE}:${THISDIR}/files:${THISDIR}:"

SRC_URI:append = " \
    file://files/default-config.yaml \
    "

do_install:append () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        sed -i 's?addresses-fallback: \[[0-9]\+\(\.[0-9]\+\)\{3\}/[0-9]\+\]?addresses-fallback: \[${ADI_CC_FALLBACK_ADDRESS}\]?' ${WORKDIR}/default-config.yaml
        install -m 644 ${WORKDIR}/default-config.yaml ${D}${sysconfdir}/netplan/default-config.yaml
    fi
}
