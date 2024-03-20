LICENSE = "CLOSED"

SRC_URI = " \
        file://bootsuccess \
        file://secondary-launcher.sh \
        file://update-bootcfg.sh \
        file://update-images.sh \
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME="bootsuccess"
INITSCRIPT_PARAMS="defaults 99"

do_install() {
    install -d          "${D}/opt"
    install -d          "${D}${sbindir}"
    install -d          "${D}${sysconfdir}"
    install -d          "${D}${sysconfdir}/init.d"
    install -m 0744     "${S}/bootsuccess"                  "${D}${sysconfdir}/init.d/bootsuccess"
    install -m 755      "${S}/secondary-launcher.sh"        "${D}${sbindir}/secondary-launcher.sh"
    install -m 755      "${S}/update-bootcfg.sh"            "${D}${sbindir}/update-bootcfg.sh"
    install -m 755      "${S}/update-images.sh"             "${D}${sbindir}/update-images.sh"
}

FILES:${PN} = " \
        /opt \
        ${sysconfdir}/init.d \
        ${sbindir}/secondary-launcher.sh \
        ${sbindir}/update-bootcfg.sh \
        ${sbindir}/update-images.sh \
    "

RDEPENDS:${PN} = " \
	dtc \
    vim \
	"
