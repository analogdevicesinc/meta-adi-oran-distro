COMPATIBLE_MACHINE ?= "titan-*"

require adrv906x-image-common.inc

IMAGE_FSTYPES:append = " jffs2"
WKS_FILE = "adrv906x-flash.wks.in"

#build flash image
require adrv906x-flash-wic.inc
do_rm_work[depends] = " adrv906x-base-jtag-image:do_image_wic"