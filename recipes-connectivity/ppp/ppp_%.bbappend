FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " \
    file://ppp/adrv906x-secondary \
    "

do_install:append () {
    mkdir -p ${D}${sysconfdir}/ppp
    mkdir -p ${D}${sysconfdir}/ppp/peers
    install -m 0755 ${WORKDIR}/ppp/adrv906x-secondary ${D}${sysconfdir}/ppp/peers/adrv906x-secondary
}

