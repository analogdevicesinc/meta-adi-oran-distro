# Copyright 2024 Analog Devices Inc.
# Released under MIT licence

# This is a temporary fix specifically for adrv904x-rd-ru.
# Since it requires devmem2, it is applied only to the debug image.
# The full fix will be made within the Kernel drivers.

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
COMPATIBLE_MACHINE = "adrv904x-rd-ru"

RDEPENDS:${PN} = " devmem2"
SRC_URI:append = " file://fifo-reset"
SRC_URI:append = " file://fifo-reset.service"

inherit systemd update-rc.d

INITSCRIPT_NAME = "fifo-reset"
INITSCRIPT_PACKAGES = "${PN}"
INITSCRIPT_PARAMS = "start 100 2 3 4 5 ."

SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'fifo-reset.service', '', d)}"

do_install() {
    install -d "${D}${sbindir}"
    install -m 0755 "${WORKDIR}/fifo-reset" "${D}${sbindir}"

    install -d "${D}${INIT_D_DIR}"
    touch "${D}${INIT_D_DIR}/fifo-reset"
    chmod +x "${D}${INIT_D_DIR}/fifo-reset"
    echo '#!/bin/sh' > "${D}${INIT_D_DIR}/fifo-reset"
    echo >> "${D}${INIT_D_DIR}/fifo-reset"
    echo "${sbindir}/fifo-reset" >> "${D}${INIT_D_DIR}/fifo-reset"
}

FILES:${PN} += "${sbindir}/fifo-reset"
