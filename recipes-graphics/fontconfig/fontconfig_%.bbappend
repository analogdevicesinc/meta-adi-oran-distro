FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:class-nativesdk = " file://environment.d-fontconfig.sh"

do_install:append:class-nativesdk () {
    mkdir -p ${D}${SDKPATHNATIVE}/environment-setup.d
    install -m 644 ${WORKDIR}/environment.d-fontconfig.sh ${D}${SDKPATHNATIVE}/environment-setup.d/fontconfig.sh
}

FILES:${PN}:append:class-nativesdk = " ${SDKPATHNATIVE}/environment-setup.d/fontconfig.sh"
