LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
        file://bootsuccess \
        file://secondary-launcher.sh \
        file://update-bootcfg.sh \
        file://update-images.sh \
        file://factory-reset.sh \
        file://mac-script.sh \
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
    install -m 755      "${S}/factory-reset.sh"             "${D}${sbindir}/factory-reset.sh"
    install -m 755      "${S}/mac-script.sh"                "${D}${sbindir}/mac-script.sh"
}

FILES:${PN} = " \
        /opt \
        ${sysconfdir}/init.d \
        ${sbindir}/secondary-launcher.sh \
        ${sbindir}/update-bootcfg.sh \
        ${sbindir}/update-images.sh \
        ${sbindir}/factory-reset.sh \
        ${sbindir}/mac-script.sh \
    "

RDEPENDS:${PN} = " \
	dtc \
    vim \
	"
