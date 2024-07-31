LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
        file://customer-provisioning.sh \
        file://customer-provisioning-deploy.sh \
    "

S = "${WORKDIR}"

do_install() {
    install -d      "${D}${sbindir}"
    install -m 755  "${S}/customer-provisioning.sh"        "${D}${sbindir}/customer-provisioning.sh"
    install -m 755  "${S}/customer-provisioning-deploy.sh" "${D}${sbindir}/customer-provisioning-deploy.sh"
}

FILES:${PN} = " \
        ${sbindir}/customer-provisioning.sh \
        ${sbindir}/customer-provisioning-deploy.sh \
    "

RDEPENDS:${PN} = " \
    sudo \
    openssl \
    bash \
	"