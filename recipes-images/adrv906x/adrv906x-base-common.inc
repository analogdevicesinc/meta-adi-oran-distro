require adrv906x-image-common.inc

adrv906x_mkext4fs () {
    mkfs.ext4 ${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ext4 -d ${IMAGE_ROOTFS} -b 4096 ${IMAGE_ROOTFS_SIZE}K
}

IMAGE_CMD:ext4 = "adrv906x_mkext4fs"
IMAGE_FSTYPES:append = " ext4"
WKS_FILE = "adrv906x-sd.wks.in"

# build SD image
require adrv906x-sd-wic.inc

# Add adi wic and initial programming tools to SDK
TOOLCHAIN_HOST_TASK:append = " nativesdk-adi-wic"
TOOLCHAIN_HOST_TASK:append = " nativesdk-adi-initial-programming"
TOOLCHAIN_HOST_TASK:append = " nativesdk-adi-initial-programming-doc"

# Add SDK dependencies for RAS application development
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-pip"
TOOLCHAIN_HOST_TASK:append = " nativesdk-mscgen"
TOOLCHAIN_HOST_TASK:append = " nativesdk-doxygen"
TOOLCHAIN_HOST_TASK:append = " nativesdk-graphviz"
TOOLCHAIN_HOST_TASK:append = " nativesdk-ninja"

# Add openssl to SDK for Ed25519 key creation and signing
TOOLCHAIN_HOST_TASK:append = " nativesdk-openssl"

do_image_wic[depends] += " adrv906x-flash-image:do_rootfs"
