SUMMARY = "a program blinks all status LEDs on Denali board, resets the board after a while"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
        file://blink-all-leds \
        file://blink-all-leds.sh \
    "

S = "${WORKDIR}"

inherit update-rc.d
INITSCRIPT_NAME = "blink-all-leds"
INITSCRIPT_PARAMS = "stop 80 1 ."

do_install() {
    install -d          "${D}${sysconfdir}/init.d"
    install -d          "${D}/usr/local/bin"
    install -m 755      "${S}/blink-all-leds"              "${D}${sysconfdir}/init.d/blink-all-leds"
    install -m 755      "${S}/blink-all-leds.sh"           "${D}/usr/local/bin/blink-all-leds.sh"
}

FILES:${PN} = " \
        ${sysconfdir}/init.d \
        ${sysconfdir}/init.d/blink-all-leds \
        /usr/local/bin/blink-all-leds.sh \
      "
