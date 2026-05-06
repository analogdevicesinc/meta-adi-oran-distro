SUMMARY = "YANG-based configuration and operational data store"
HOMEPAGE = "https://github.com/sysrepo/sysrepo"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=ef345f161efb68c3836e6f5648b2312f"

SRC_URI = "git://github.com/sysrepo/sysrepo;protocol=https;branch=master \
           ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'file://sysrepo','', d)} \
           ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'file://sysrepod.service','', d)} \
           file://0001-Do-not-use-hard-coded-tar-path.patch \
           file://0002-modules-iana-if-types-revision-upgrade.patch \
           "
SRCREV = "b686dd854f330c1a8fcd753abf0dc9becac0032e"
PV = "4.5.4"
S = "${WORKDIR}/git"
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

DEPENDS = "libyang"

inherit cmake pkgconfig
inherit ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'update-rc.d', '', d)}
inherit ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}
BBCLASSEXTEND = "native nativesdk"

EXTRA_OECMAKE = " \
    -DCMAKE_INSTALL_PREFIX:PATH=${prefix} \
    -DCMAKE_BUILD_TYPE:String=Release \
    -DENABLE_EXAMPLES:String=OFF \
    -DENABLE_TESTS:String=OFF \
    -DREPO_PATH:PATH=/data/active/etc/sysrepo \
    -DPRINTED_CONTEXT_ADDRESS=0 \
"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "sysrepod.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

INITSCRIPT_NAME = "sysrepo"
INITSCRIPT_PARAMS = "disable"

RDEPENDS:${PN} += "tar"

do_install:append:class-target () {
    install -d ${D}${sysconfdir}/init.d

    if ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}; then
        install -m 0775 ${WORKDIR}/sysrepo ${D}${sysconfdir}/init.d/
        install -d ${D}${libdir}/sysrepo/plugins
    fi

    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/sysrepod.service ${D}${systemd_system_unitdir}
    fi
}

FILES:${PN}:append = " \
    ${libdir}/sysrepo-plugind/* \
    ${datadir}/yang/modules/sysrepo/* \
    /data/active/etc/sysrepo"
