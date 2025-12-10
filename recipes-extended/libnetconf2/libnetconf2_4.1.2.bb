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
SRCREV = "84c60d815a10a4f9a99f6c003f7232808eb8ac7a"
PV = "4.1.2"
S = "${WORKDIR}/git"
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

DEPENDS = "libssh openssl libyang libxcrypt curl virtual/crypt"
inherit cmake pkgconfig
BBCLASSEXTEND = "native nativesdk"

EXTRA_OECMAKE = "-DCMAKE_INSTALL_PREFIX:PATH=${prefix} -DCMAKE_BUILD_TYPE:String=Release"

FILES:${PN}:append = " ${datadir}/yang/modules/libnetconf2/*"

