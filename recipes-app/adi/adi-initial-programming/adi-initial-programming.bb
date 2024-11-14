DESCRIPTION = "ADI tools for initial programming of eMMC and QSPI"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://configure_tftp_server.sh"
SRC_URI:append = " file://configure.env"
SRC_URI:append = " file://supervisor.sh"
SRC_URI:append = " file://README"

RDEPENDS:${PN}:append = "bash tftp-hpa-server"

do_install() {
    # Install our scripts
    mkdir -p "${D}${bindir}"
    mkdir -p "${D}${sysconfdir}/initialprogramming/"
    install -d "${D}${datadir}/doc/initialprogramming/"
    install -m 755  "${WORKDIR}/configure_tftp_server.sh"         "${D}${bindir}/adi_configure_tftp_server"
    install -m 755  "${WORKDIR}/supervisor.sh"                    "${D}${bindir}/adi_initial_programming_supervisor"
    install -m 755  "${WORKDIR}/configure.env"                    "${D}${sysconfdir}/initialprogramming/configure.env"
    install -m 0644 "${WORKDIR}/README"                           "${D}${datadir}/doc/initialprogramming/README"
}

FILES:${PN} = " ${bindir} \
                ${datadir}/doc/initialprogramming/README \
                ${sysconfdir} "
BBCLASSEXTEND = "native nativesdk"
