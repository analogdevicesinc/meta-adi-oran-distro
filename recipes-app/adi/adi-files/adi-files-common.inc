LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI:append = " file://startup.sh"
SRC_URI:append = " file://temp-mon.sh"
SRC_URI:append:adrv904x-rd-ru = " file://poweroff.sh"
SRC_URI:append = " file://environment"
SRC_URI:append:adrv904x-rd-ru = " file://adrv904x-rd-ru-heartbeat.sh"

SRC_URI:append = " file://uiomem"
SRC_URI:append = " file://led_apps/"

RDEPENDS:${PN} = "bash"

S = "${WORKDIR}/${BPN}-${PV}-${MACHINE}"

install_dirs() {
    install -d "${D}/opt"
    install -d "${D}${sbindir}"
    install -d "${D}/etc"
}

do_install:prepend:adrv904x-rd-ru() {
    install_dirs

    sed -i "10i#Set bit13 of 0xF9142820 to enable power to RF transceiver(Koror) on adrv904x-rd-ru board."   "${WORKDIR}/startup.sh"
    sed -i 's/#ENABLE-TRANSCEIVERS#/\/opt\/uiomem 0xF9142820 0x2000 \&> \/dev\/null #ENABLE-TRANSCEIVERS#/g' "${WORKDIR}/startup.sh"

    #install poweroff
    install -m 755 "${WORKDIR}/poweroff.sh"         "${D}${sbindir}"

    #install led apps
    install -d "${D}/opt/led_apps"
    install -m 755 "${WORKDIR}/led_apps/blink"         "${D}/opt/led_apps/"
    install -m 755 "${WORKDIR}/led_apps/hello"         "${D}/opt/led_apps/"
    install -m 755 "${WORKDIR}/led_apps/scroll_client" "${D}/opt/led_apps/"
    install -m 755 "${WORKDIR}/led_apps/scroll_server" "${D}/opt/led_apps/"
    install -m 755 "${WORKDIR}/led_apps/toggle"        "${D}/opt/led_apps/"
}

do_install() {
    install_dirs

    #install uiomem
    install -m 755 "${WORKDIR}/uiomem"      "${D}/opt"
    ln -s -r ${D}/opt/uiomem ${D}${sbindir}/uiomem

    #install heartbeat
    if [ -f "${WORKDIR}/${MACHINE}-heartbeat.sh" ]; then
        cp "${WORKDIR}/${MACHINE}-heartbeat.sh"        "${WORKDIR}/heartbeat.sh"
        install -m 755 "${WORKDIR}/heartbeat.sh"       "${D}${sbindir}"
    fi
    install -m 755 "${WORKDIR}/startup.sh"         "${D}${sbindir}"

    #install temp-mon
    install -m 755 "${WORKDIR}/temp-mon.sh"       "${D}${sbindir}"

    #install /etc/environment file
    sed -i 's/${platform_name}/${PLATFORM_NAME_VER}/g'    ${WORKDIR}/environment
    install -m 755 "${WORKDIR}/environment"       "${D}/etc"
}

do_install:append(){
    if ${@bb.utils.contains('ADI_CC_SYSTEMD_INIT', '1', 'true', 'false', d)}; then
        do_install_systemd_services
    else
        do_install_sysvinit_services
    fi
}

#shipped the installed files to /opt in the rootfs:
FILES:${PN}:append = " ${sbindir}/* /etc/environment /opt/*"
INSANE_SKIP:${PN} = "ldflags"
