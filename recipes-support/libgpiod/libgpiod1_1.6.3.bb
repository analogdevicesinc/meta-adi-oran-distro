SUMMARY = "ADI custom version of libgipod_1.x.x recipe to build the gpiod library"

LICENSE = "LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://COPYING;md5=2caced0b25dfefd4c601d92bd15116de"

SRC_URI = "https://www.kernel.org/pub/software/libs/libgpiod/libgpiod-${PV}.tar.xz"

SRC_URI[sha256sum] = "841be9d788f00bab08ef22c4be5c39866f0e46cb100a3ae49ed816ac9c5dddc7"

inherit autotools pkgconfig

PACKAGECONFIG = ""

DEPENDS += "autoconf-archive-native"

# libgpiod-${PV}.tar.xz gets uncompressed as libgpiod-${PV}, so
# we need to set our sources dir to libgpiod-${PV} instead of ${PN}-${PV}
S = "${WORKDIR}/libgpiod-${PV}"

# Overwrite the install task to just install libgpiod.so.2 (libgpiod_1.6.3)
do_install() {
    mkdir -p ${D}/usr/lib
    install -m 644 ${B}/lib/.libs/libgpiod.so ${D}/usr/lib/libgpiod.so.2
}

