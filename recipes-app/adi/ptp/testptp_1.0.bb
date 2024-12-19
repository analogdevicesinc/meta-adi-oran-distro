DESCRIPTION = "Linux selftest tool for PTP Hardware Clock"
LICENSE = "MIT"

SRC_URI = " \
        https://raw.githubusercontent.com/torvalds/linux/3a9a9a6139286584d1199f555fa4f96f592a3217/tools/testing/selftests/ptp/testptp.c;md5sum=0f7568fad55ecf8ae96678153f3ae4de \
        https://raw.githubusercontent.com/torvalds/linux/3a9a9a6139286584d1199f555fa4f96f592a3217/COPYING;md5sum=6bc538ed5bd9a7fc9398086aedcd7e46 \
        "
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

S = "${WORKDIR}"
do_compile () {
    ${CC} testptp.c ${LDFLAGS} -o testptp
}

do_install () {
	install -d ${D}${bindir}/
	install -m 0755 ${S}/testptp ${D}${bindir}/
}

FILES:${PN} = "${bindir}/testptp"

RPROVIDES:${PN}:append = " testptp"