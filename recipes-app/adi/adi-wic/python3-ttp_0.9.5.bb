SUMMARY = "TTP is a Python library for semi-structured text parsing using templates."
HOMEPAGE = "https://pypi.org/project/ttp/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=bf154be045e4cdaea9c1045f7a12e7ce"

SRC_URI[sha256sum] = "234414f4d3039d2d1cde09993f89f8db1b34d447f76c6a402555cefac2e59c4e"

S = "${WORKDIR}/ttp-0.9.5"

inherit pypi python_poetry_core

BBCLASSEXTEND = "native nativesdk"
