SUMMARY = "Cisco-like telnet command-line library"
LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=cb8aedd3bced19bd8026d96a8b6876d7"

SRC_URI = "git://github.com/dparrish/libcli.git;protocol=https;branch=stable"
SRCREV = "0f8d257612a5c62000a55fd00e79a35f813f0375"

S = "${WORKDIR}/git"

DEPENDS:append = " libxcrypt"

do_compile() {
	oe_runmake 'CC=${CC}' 'AR=${AR}'
}

do_install() {
	oe_runmake install 'DESTDIR=${D}' 'PREFIX=${prefix}'
}

FILES:${PN} += "${libdir}/libcli.so* ${includedir}/libcli.h"
