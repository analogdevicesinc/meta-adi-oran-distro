SUMMARY = "0mq 'highlevel' C++ bindings"
HOMEPAGE = "http://www.zeromq.org"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=815ca599c9df247a0c7f619bab123dad"
DEPENDS = "zeromq"

SRC_URI = "git://github.com/zeromq/zmqpp.git;protocol=https;branch=master"
PV = "4.2.0"

SRCREV = "f8ff127683dc555aa004c0e6e2b18d2354a375be"

S = "${WORKDIR}/git"

inherit cmake
FILES_SOLIBS = ".so"
FILES_SOLIBSDEV = ""
FILES:${PN} = "${libdir}/*.so"
FILES:${PN}-dev:append = " ${includedir} ${datadir}/cmake"
FILES:${PN}-staticdev:append = " ${libdir}/lib*.a"

RDEPENDS:${PN}-dev = "zeromq-dev"
