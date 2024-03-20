SUMMARY = "ADRV906x base sd image with jtag enabled"
LICENSE = "MIT"

COMPATIBLE_MACHINE:append ?= "titan-*|"

# create `adrv906x-base-jtag-image` will also create `adrv906x-flash-image`
DEPENDS:append = " adrv906x-flash-image"

require adrv906x-base-common.inc

ROOTFS_IMAGE_DIR ?= "${IMGDEPLOYDIR}"
APP_PACK_IMAGE   ?= "debug_app_pack.bin"

do_custom_install(){
    install -d ${D}/dm-verity
    install -m 644 ${IMGDEPLOYDIR}/${DM_VERITY_IMAGE}-${MACHINE}.ext4.verity  ${D}/dm-verity
}

do_rootfs_wicenv:append(){
    bb.build.exec_func('do_custom_install', d)
}

create_rootfs_image_alias() {
    if [ -L ${IMGDEPLOYDIR}/adrv906x-base-image-${MACHINE}.ext4.verity ]; then
        rm ${IMGDEPLOYDIR}/adrv906x-base-image-${MACHINE}.ext4.verity
    fi
    ln -s -r ${IMGDEPLOYDIR}/${DM_VERITY_IMAGE}-${MACHINE}.ext4.verity \
        ${IMGDEPLOYDIR}/adrv906x-base-image-${MACHINE}.ext4.verity
}

do_image_complete:append() {
    bb.build.exec_func('create_rootfs_image_alias', d)
}

addtask rootfs_wicenv before do_populate_sysroot after do_image_ext4
addtask install before do_image_wic after do_rootfs_wicenv
addtask do_install
addtask do_populate_sysroot
addtask populate_sysroot before do_image_complete after do_install

# share to adrv906x-base-image
SYSROOT_DIRS:append = " /dm-verity"
