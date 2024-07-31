SUMMARY = "reduce fan speed to keep it quiet to start with, RAS will adjust fan speed later"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

COMPATIBLE_MACHINE = "titan-*|denali-*"

RDEPENDS:${PN} = " bash"

SRC_URI = " \
        file://reduce-fan-speed \
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = "reduce-fan-speed"
INITSCRIPT_PARAMS = "start 80 5 ."

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
    install -m 755      "${S}/reduce-fan-speed"    "${D}${sysconfdir}/init.d/reduce-fan-speed"
}

FILES:${PN} = " \
        ${sysconfdir}/init.d \
        ${sysconfdir}/init.d/reduce-fan-speed \
      "
