DESCRIPTION = "ADI tools for modifying WIC images"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://modify_wic.sh"

RDEPENDS:${PN} += "bash"

wic_dirname = "$(dirname $(which wic))"

do_install() {
    # Install wic-related files from poky
    install -d      "${D}${bindir}/lib/wic"
    install -m 755  "${wic_dirname}/wic"                "${D}${bindir}"
    install -m 755  "${wic_dirname}/lib/scriptpath.py"  "${D}${bindir}/lib"
    cp -r           "${wic_dirname}/lib/wic"            "${D}${bindir}/lib"

    # Install our scripts
    install -m 755  "${WORKDIR}/modify_wic.sh"          "${D}${bindir}"
}

FILES:${PN} = " ${bindir} \
                ${libdir} "

BBCLASSEXTEND = "native nativesdk"
