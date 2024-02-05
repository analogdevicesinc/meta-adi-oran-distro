require adi-files-common.inc

SRC_URI:append = " file://heartbeat.service"
SRC_URI:append = " file://startup.service"
SRC_URI:append = " file://temp-mon.service"
SRC_URI:append:adrv904x-rd-ru = " file://poweroff.service"

inherit systemd features_check

do_install_systemd_services() {
    install -d "${D}${systemd_system_unitdir}"
    install -m 644 "${WORKDIR}/heartbeat.service"  "${D}${systemd_system_unitdir}"
    install -m 644 "${WORKDIR}/startup.service"    "${D}${systemd_system_unitdir}"
    install -m 644 "${WORKDIR}/temp-mon.service"  "${D}${systemd_system_unitdir}"
}

do_install_systemd_services:append:adrv904x-rd-ru() {
    install -m 644 "${WORKDIR}/poweroff.service"    "${D}${systemd_system_unitdir}"
}

FILES:${PN}:append = " ${systemd_system_unitdir}/*"

REQUIRED_DISTRO_FEATURES = "systemd"
SYSTEMD_SERVICE:${PN}  = "startup.service heartbeat.service temp-mon.service"
SYSTEMD_SERVICE:${PN}:append:adrv904x-rd-ru  = " poweroff.service"
SYSTEMD_AUTO_ENABLE = "enable"
