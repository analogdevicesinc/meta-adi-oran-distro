LICENSE = "CLOSED"

SRC_URI = " \
        file://data-partition.sh \
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME="data-partition.sh"
INITSCRIPT_PARAMS="start 00 S ."

do_install() {
    install -d          "${D}/${sysconfdir}"
    install -d          "${D}/data"
    install -d          "${D}/data/defaults"
    install -d          "${D}/data/active"
    install -d          "${D}${sysconfdir}/init.d"
    install -m 0744     "${S}/data-partition.sh"    "${D}${sysconfdir}/init.d/data-partition.sh"
}

FILES:${PN} = " \
        ${sysconfdir}/init.d \
        /data \
        /data/defaults \
        /data/active \
    "
