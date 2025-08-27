SUMMARY = "NETCONF protocol library"
DESCRIPTION = "The library provides functions to connect NETCONF client and server to each other via SSH and to send, receive and process NETCONF messages."
HOMEPAGE = "https://github.com/CESNET/libnetconf2"
SECTION = "libs"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=08a5578c9bab06fb2ae84284630b973f"

SRC_URI = "git://github.com/CESNET/libnetconf2;protocol=https;branch=master \
           file://0001-Disable-deprecated-functions-warning.patch \
           file://0002-modules-iana-crypt-hash-revision-upgrade.patch \
           "
SRCREV = "61fbe731908809f88a187f223d43718479a7e0da"
PV = "3.7.10"
S = "${WORKDIR}/git"
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

DEPENDS = "libssh openssl libyang libxcrypt curl"
inherit cmake pkgconfig
BBCLASSEXTEND = "native nativesdk"

EXTRA_OECMAKE = "-DCMAKE_INSTALL_PREFIX:PATH=${prefix} -DCMAKE_BUILD_TYPE:String=Release"

FILES:${PN}:append = " ${datadir}/yang/modules/libnetconf2/*"

