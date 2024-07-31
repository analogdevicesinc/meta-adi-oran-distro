SUMMARY = "Boot Debugging Image for ADI O-RAN platforms, suitable for debug use."
LICENSE = "MIT"

require recipes-images/poky/adi-console-image.bb
export IMAGE_BASENAME = "adi-console-debug-image"

# Remove Firewall
IMAGE_INSTALL:remove = "nftables"

PACKAGE_GROUPS_FPGA_DEBUG = " \
    packagegroup-adi-debug \
    packagegroup-core-tools-debug \
    packagegroup-core-buildessential \
    packagegroup-core-tools-profile \
    "

PACKAGE_GROUPS_DEBUG ?= " "
PACKAGE_GROUPS_DEBUG:adrv904x-rd-ru = "${PACKAGE_GROUPS_FPGA_DEBUG}"

IMAGE_INSTALL:append = "${PACKAGE_GROUPS_DEBUG}"

ROOTFS_IMAGE_DIR = "${RECIPE_SYSROOT}/dm-verity"

create_jtag_image_alias() {
    if [ -L ${DEPLOY_DIR_IMAGE}/adi-console-debug-jtag-image-${MACHINE}.wic ]; then
        rm ${DEPLOY_DIR_IMAGE}/adi-console-debug-jtag-image-${MACHINE}.wic
    fi

    if [ -L ${DEPLOY_DIR_IMAGE}/adi-console-debug-jtag-image-${MACHINE}.wic.gz ]; then
        rm ${DEPLOY_DIR_IMAGE}/adi-console-debug-jtag-image-${MACHINE}.wic.gz
    fi

    ln -s -r ${DEPLOY_DIR_IMAGE}/adrv906x-base-jtag-image-${MACHINE}.wic \
        ${DEPLOY_DIR_IMAGE}/adi-console-debug-jtag-image-${MACHINE}.wic

    ln -s -r ${DEPLOY_DIR_IMAGE}/adrv906x-base-jtag-image-${MACHINE}.wic.gz \
        ${DEPLOY_DIR_IMAGE}/adi-console-debug-jtag-image-${MACHINE}.wic.gz
}

do_image_complete:append() {
    if d.getVar('ADI_SOC') == 'adrv906x':
        bb.build.exec_func('create_jtag_image_alias', d)
}
