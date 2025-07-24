SUMMARY = "ADRV906x swupdate image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

DEPENDS:append = " ${DM_VERITY_IMAGE}"
do_swuimage[depends] = "${DM_VERITY_IMAGE}:do_image_complete"

require adrv906x-partitions.inc
IMAGE_NAME_SUFFIX = ""
HWREV ?= "A"

inherit swupdate
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend := "${THISDIR}/files/swu:"
SRC_URI:append = " \
    file://sw-description \
    file://update-slot.sh \
    file://swupdate-priv.pass \
    file://swupdate-priv.pem \
"

def get_openssl_flags(d):
    key = d.getVar('SWUPDATE_PRIVATE_KEY', expand=True)
    flags = ''
    if key.startswith('pkcs11:'):
        flags += '-keyform engine -engine pkcs11'
    return flags

def get_openssl_engines(d):
    key = d.getVar('SWUPDATE_PRIVATE_KEY', expand=True)
    val = ''
    if key.startswith('pkcs11:'):
        val += d.getVar('RECIPE_SYSROOT_NATIVE') + '/usr/lib/engines-3/'
    return val

def get_pkcs11_module(d):
    key = d.getVar('SWUPDATE_PRIVATE_KEY', expand=True)
    val = ''
    if key.startswith('pkcs11:'):
        val += d.getVar('RECIPE_SYSROOT_NATIVE') + '/usr/lib/pkcs11/p11-kit-client.so'
    return val

def get_extra_depends(d):
    key = d.getVar('SWUPDATE_PRIVATE_KEY', expand=True)
    val = ''
    if key.startswith('pkcs11:'):
        val += 'libp11-native p11-kit-native'
    return val

DEPENDS:append = " ${@get_extra_depends(d)}"

SWUPDATE_SRC_URI_EXCLUDE = "swupdate-priv.pass swupdate-priv.pem"
SWUPDATE_PRIVATE_KEY = "${WORKDIR}/swupdate-priv.pem"
SWUPDATE_PASSWORD_FILE = "${WORKDIR}/swupdate-priv.pass"

export OPENSSL_ENGINES="${@get_openssl_engines(d)}"
export PKCS11_MODULE_PATH="${@get_pkcs11_module(d)}"
export P11_KIT_SERVER_ADDRESS
export P11_KIT_SERVER_PID

SWUPDATE_SIGNING = "CUSTOM"
SWUPDATE_SIGN_TOOL := "openssl dgst -sha256 -sign ${SWUPDATE_PRIVATE_KEY} -passin file:${SWUPDATE_PASSWORD_FILE} ${@ get_openssl_flags(d) } -out ${S}/sw-description.sig ${S}/sw-description"
SWUPDATE_IMAGES = " \
    fip.bin \
    fitImage-${INITRAMFS_IMAGE}-${MACHINE}-${MACHINE} \
    ${DM_VERITY_IMAGE}-${MACHINE}.ext4.verity.gz \
"
