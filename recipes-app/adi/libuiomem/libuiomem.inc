require include/fetch-utils.inc

RPROVIDES:${PN}:append = " uiomem"

SRC_URI = "git://github.com/analogdevicesinc/uiomem.git;branch=main;protocol=https"
SRCREV ?= "${AUTOREV}"
PV ?= "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

inherit cmake

EXTRA_OECMAKE ?= "-DBUILD_SHARED_LIBS=ON"

FILES:${PN}-uiomem = "${sbindir}/uiomem"

