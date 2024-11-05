SUMMARY = "Start CPU cores supervisor based on optee app"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
        file://cpu-cores-alive\
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = "cpu-cores-alive"
INITSCRIPT_PARAMS = "start 99 5 . stop 40 0 ."

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
    install -m 755      "${S}/cpu-cores-alive"              "${D}${sysconfdir}/init.d/cpu-cores-alive"
}

FILES:${PN} = " \
        ${sysconfdir}/init.d \
        ${sysconfdir}/init.d/cpu-cores-alive \
      "
