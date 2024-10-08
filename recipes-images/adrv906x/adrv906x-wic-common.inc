DEPENDS:append = " bootctrl debug-app-pack app-pack data-partition gptfdisk-native dosfstools-native"
do_image_wic[depends] += " bootctrl:do_deploy debug-app-pack:do_install app-pack:do_install data-partition:do_install"
WKS_FILE_DEPENDS = " parted-native virtual/bootloader virtual/kernel"
IMAGE_FSTYPES:append = " wic wic.gz"

require adrv906x-partitions.inc

WIC_CREATE_EXTRA_ARGS:append = " -i adi-direct"
WICVARS:append = " IMAGE_TOTAL_SIZE"

#change do_image_wic's order
addtask image_wic before do_image_complete after do_image_ext4
