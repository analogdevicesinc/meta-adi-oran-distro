require recipes-images/poky/adi-console-image.bb

IMAGE_INSTALL:append = " \
    packagegroup-adi-debug \
    packagegroup-core-tools-debug \
    packagegroup-core-buildessential \
    packagegroup-core-tools-profile \
    "

export IMAGE_BASENAME = "adi-console-debug-image"

