SUMMARY = "Hardware RNG based on CPU timing jitter"
DESCRIPTION = "The Jitter RNG provides a noise source using the CPU execution timing jitter. \
It does not depend on any system resource other than a high-resolution time \
stamp. It is a small-scale, yet fast entropy source that is viable in almost \
all environments and on a lot of CPU architectures."
HOMEPAGE = "http://www.chronox.de/jent.html"
LICENSE = "GPL-2.0-or-later | BSD-3-Clause"
LIC_FILES_CHKSUM = "file://COPYING;md5=fd977300692e5bf78d4b714706654e53 \
                    file://COPYING.gplv2;md5=eb723b61539feef013de476e68b5c50a \
                    file://COPYING.bsd;md5=66a5cedaf62c4b2637025f049f9b826f \
                    "
SRC_URI = "git://github.com/smuellerDD/jitterentropy-rngd.git;branch=master;protocol=https \
           file://init \
           "
SRCREV = "ade61a1548a2754d38f0c0c18f52b80d9a599420"
S = "${WORKDIR}/git"

TARGET_CFLAGS += "-Wextra -Wall -pedantic -fwrapv --param ssp-buffer-size=4 -fvisibility=hidden -fPIE -Wcast-align -Wmissing-field-initializers -Wshadow -Wswitch-enum -O0"

do_configure[noexec] = "1"

do_compile () {
    oe_runmake all
}

do_install () {
    install -d "${D}${sbindir}"
    install -m 0755 "${S}/jitterentropy-rngd"      "${D}${sbindir}"
    install -Dm 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/jitterentropy
}

inherit update-rc.d
INITSCRIPT_NAME="jitterentropy"
INITSCRIPT_PARAMS="defaults 9"
