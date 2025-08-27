SUMMARY = "Implementation of network configuration tools based on NETCONF Protocol"
DESCRIPTION = "Netopeer2 is based on the new generation of the NETCONF and YANG libraries - libyang and libnetconf2. The Netopeer server uses sysrepo as a NETCONF datastore implementation."
HOMEPAGE = "https://github.com/CESNET/netopeer2"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=41daedff0b24958b2eba4f9086d782e1"

PACKAGES += "${PN}-server ${PN}-cli"

SRC_URI = " \
    git://github.com/CESNET/netopeer2;protocol=https;branch=master \
    ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'file://netopeer2-server', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'file://netopeer2-serverd.service', '', d)} \
    file://0001-modules-iana-crypt-hash-revision-upgrade.patch \
"

SRCREV = "2549f8f73b61e94f031a84bf709cbb4e3d594a94"
PV = "2.4.5"
S = "${WORKDIR}/git"

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

DEPENDS = "libyang libnetconf2 sysrepo sysrepo-native"
RDEPENDS:${PN}-server = "bash curl"
inherit cmake pkgconfig

inherit ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'update-rc.d', '', d)}
inherit ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}

# enable native build
BBCLASSEXTEND = "native nativesdk"

EXTRA_OECMAKE = " \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE:String=Release \
    -DENABLE_TESTS=OFF \
    -DSYSREPO_SETUP=OFF \
"

SYSTEMD_PACKAGES = "${PN}-server"
SYSTEMD_SERVICE:${PN}-server = "netopeer2-serverd.service"
SYSTEMD_AUTO_ENABLE:${PN}-server = "disable"

INITSCRIPT_PACKAGES = "${PN}-server"
INITSCRIPT_NAME:${PN}-server = "${PN}-server"
INITSCRIPT_PARAMS:${PN}-server = "disable"

do_install:append () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${WORKDIR}/netopeer2-server ${D}${sysconfdir}/init.d/
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/netopeer2-serverd.service ${D}${systemd_system_unitdir}
    fi

    rm -rf ${D}${sysconfdir}/pam.d
}

FILES:${PN} = ""

FILES:${PN}-server = " \
    ${sysconfdir} \
    ${sysconfdir}/init.d/netopeer2-server \
    ${systemd_system_unitdir}/netopeer2-serverd.service \
    ${sbindir}/netopeer2-server \
    ${datadir}/netopeer2/scripts/* \
    ${datadir}/yang/modules/netopeer2/*"

FILES:${PN}-cli = " \
    ${bindir}/netopeer2-cli \
"

# main package is empty but depends on sub-packages
RDEPENDS:${PN} = "${PN}-server ${PN}-cli"
ALLOW_EMPTY:${PN} = "1"
