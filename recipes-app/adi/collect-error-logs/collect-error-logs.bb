SUMMARY = "Start CPU cores supervisor based on optee app"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
        file://collect-error-logs \
        file://collect-boot-runtime-logs.sh \
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = "collect-error-logs"
INITSCRIPT_PARAMS = "start 99 5 . stop 40 0 ."

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
    install -d          "${D}${sbindir}"
    install -m 755      "${S}/collect-error-logs"              "${D}${sysconfdir}/init.d/collect-error-logs"
    install -m 755      "${S}/collect-boot-runtime-logs.sh"    "${D}${sbindir}/collect-boot-runtime-logs.sh"
}

FILES:${PN} = " \
        ${sysconfdir}/init.d \
        ${sysconfdir}/init.d/collect-error-logs \
        ${sbindir}/collect-boot-runtime-logs.sh \
      "
