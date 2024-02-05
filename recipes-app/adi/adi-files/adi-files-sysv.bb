DEPENDS:append = " update-rc.d-native"
require adi-files-common.inc

SRC_URI:append = " file://start_heart.sh"

make_dirs() {
    install -d ${D}${sysconfdir}/init.d
    install -d ${D}${sysconfdir}/rcS.d
    install -d ${D}${sysconfdir}/rc0.d
    install -d ${D}${sysconfdir}/rc1.d
    install -d ${D}${sysconfdir}/rc2.d
    install -d ${D}${sysconfdir}/rc3.d
    install -d ${D}${sysconfdir}/rc4.d
    install -d ${D}${sysconfdir}/rc5.d
    install -d ${D}${sysconfdir}/rc6.d
}

do_install_sysvinit_services() {
    make_dirs
    install -m 0755 "${WORKDIR}/start_heart.sh"       "${D}${sbindir}"
    install -m 0755 ${D}${sbindir}/start_heart.sh  ${D}${sysconfdir}/init.d
    install -m 0755 ${D}${sbindir}/temp-mon.sh  ${D}${sysconfdir}/init.d
    sed -i "s/netplan\/\*config.yaml/network\/interfaces/g" ${D}${sbindir}/startup.sh
    install -m 0755 ${D}${sbindir}/startup.sh  ${D}${sysconfdir}/init.d

    # Create runlevel links
    update-rc.d -r ${D} start_heart.sh start 100 2 3 4 5 .
    update-rc.d -r ${D} temp-mon.sh start 100 2 3 4 5 .
    update-rc.d -r ${D} startup.sh start 100 2 3 4 5 .
}

do_install_sysvinit_services:adrv904x-rd-ru:append() {
    make_dirs
    install -m 0755 ${D}${sbindir}/poweroff.sh  ${D}${sysconfdir}/init.d
    update-rc.d -r ${D} poweroff.sh start 100 6 .
}
