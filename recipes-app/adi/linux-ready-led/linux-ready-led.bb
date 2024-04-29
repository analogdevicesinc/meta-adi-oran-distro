SUMMARY = "turn on LED0 when linux reaches run level 5 (network service ready)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
        file://linux-ready-led \
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = "linux-ready-led"
INITSCRIPT_PARAMS = "start 99 5 . stop 40 1 ."

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
    install -m 755      "${S}/linux-ready-led"              "${D}${sysconfdir}/init.d/linux-ready-led"
}

FILES:${PN} = " \
        ${sysconfdir}/init.d \
        ${sysconfdir}/init.d/linux-ready-led \
      "
