COMPATIBLE_MACHINE ?= "titan-*"

require adrv906x-image-common.inc

adrv906x_mkext4fs () {
    mkfs.ext4 ${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ext4 -d ${IMAGE_ROOTFS} -b 4096 240M
}

IMAGE_CMD:ext4 = "adrv906x_mkext4fs"
IMAGE_FSTYPES:append = " ext4"
WKS_FILE = "adrv906x-sd.wks.in"

# build SD image
require adrv906x-sd-wic.inc

# Add adi wic tools to SDK
TOOLCHAIN_HOST_TASK:append = " nativesdk-adi-wic"

do_image_wic[depends] += " adrv906x-flash-image:do_rootfs"
