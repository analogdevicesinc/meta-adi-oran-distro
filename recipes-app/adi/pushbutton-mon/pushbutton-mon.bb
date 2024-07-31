SUMMARY = "monitoring the push button that can be presssed by a user"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

COMPATIBLE_MACHINE = "titan|denali"

RDEPENDS:${PN} = " bash"
DEPENDS:append = " libgpiod"

SRC_URI = " \
        file://pushbutton-mon \
        file://pushbutton-mon.sh \
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = "pushbutton-mon"
INITSCRIPT_PARAMS = "start 80 5 ."

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
    install -d          "${D}/usr/local/bin"
    install -m 755      "${S}/pushbutton-mon"              "${D}${sysconfdir}/init.d/pushbutton-mon"
    install -m 755      "${S}/pushbutton-mon.sh"           "${D}/usr/local/bin/pushbutton-mon.sh"
}

FILES:${PN} = " \
        ${sysconfdir}/init.d \
        ${sysconfdir}/init.d/pushbutton-mon \
        /usr/local/bin/pushbutton-mon.sh \
      "
