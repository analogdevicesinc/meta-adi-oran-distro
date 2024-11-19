FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "${@bb.utils.contains('ADI_CC_BOOT_DEBUG','1',' file://0001-Add-debug-config.patch','', d)}"
