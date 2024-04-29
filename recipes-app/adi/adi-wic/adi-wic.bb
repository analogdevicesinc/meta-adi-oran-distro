DESCRIPTION = "ADI tools for modifying WIC images"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://adi_modify_wic.sh"
SRC_URI:append = " file://adi_extract_kernel_fit_images.sh"
SRC_URI:append = " file://adi_extract_wic_images.sh"
SRC_URI:append = " file://adi_modify_kernel_fit.sh"
SRC_URI:append = " file://adi_generate_its_from_fit.py"

RDEPENDS:${PN} += "bash python3-ttp u-boot-tools"

wic_dirname = "$(dirname $(which wic))"

do_install() {
    # Install wic-related files from poky
    install -d      "${D}${bindir}/lib/wic"
    install -m 755  "${wic_dirname}/wic"                "${D}${bindir}"
    install -m 755  "${wic_dirname}/lib/scriptpath.py"  "${D}${bindir}/lib"
    cp -r           "${wic_dirname}/lib/wic"            "${D}${bindir}/lib"

    # Install our scripts
    install -m 755  "${WORKDIR}/adi_modify_wic.sh"                "${D}${bindir}/adi_modify_wic"
    install -m 755  "${WORKDIR}/adi_extract_kernel_fit_images.sh" "${D}${bindir}/adi_extract_kernel_fit_images"
    install -m 755  "${WORKDIR}/adi_extract_wic_images.sh"        "${D}${bindir}/adi_extract_wic_images"
    install -m 755  "${WORKDIR}/adi_modify_kernel_fit.sh"         "${D}${bindir}/adi_modify_kernel_fit"
    install -m 755  "${WORKDIR}/adi_generate_its_from_fit.py"     "${D}${bindir}/adi_generate_its_from_fit"
}

FILES:${PN} = " ${bindir} \
                ${libdir} "
BBCLASSEXTEND = "native nativesdk"
