SUMMARY = "ADRV906x wic image creation for nor flash"

require adrv906x-wic-common.inc

#Offset takes advantage for wic on disk creation, when sit together for part command line,
#size yelids by reducing 2 sectors(1024 bytes) which won't sacrifie build results from adrv906x-flash.wks.in file.
def convert_size(byte_count):
    kibibytes = (int(byte_count) - 1024) // 1024
    return f'{kibibytes}K'

def convert_offset(byte_count):
    sector = int(byte_count) // 512
    # add one to account for MBR
    return f'{sector+1}s'

NOR_BOOT_A_START ??= "0"
NOR_BOOT_B_START ??= "0"
NOR_BOOT_SIZE ??= "0"
NOR_BOOTCTRL_START ??= "0"
NOR_BOOTCTRL_SIZE ??= "0"
NOR_BOOTCFG_START ??= "0"
NOR_BOOTCFG_SIZE ??= "0"
NOR_FIP_A_START ??= "0"
NOR_FIP_B_START ??= "0"
NOR_FIP_SIZE ??= "0"
NOR_KERNEL_A_START ??= "0"
NOR_KERNEL_B_START ??= "0"
NOR_KERNEL_SIZE ??= "0"

BOOTCTRL_PART_SIZE = "${@convert_size(d.getVar('NOR_BOOTCTRL_SIZE'))}"
BOOTCFG_PART_SIZE = "${@convert_size(d.getVar('NOR_BOOTCFG_SIZE'))}"
BOOT_PART_SIZE = "${@convert_size(d.getVar('NOR_BOOT_SIZE'))}"
FIP_PART_SIZE = "${@convert_size(d.getVar('NOR_FIP_SIZE'))}"
KERNEL_PART_SIZE = "${@convert_size(d.getVar('NOR_KERNEL_SIZE'))}"

BOOT_A_PART_OFFSET = "${@convert_offset(d.getVar('NOR_BOOT_A_START'))}"
BOOT_B_PART_OFFSET = "${@convert_offset(d.getVar('NOR_BOOT_B_START'))}"
BOOTCTRL_PART_OFFSET = "${@convert_offset(d.getVar('NOR_BOOTCTRL_START'))}"
BOOTCFG_PART_OFFSET = "${@convert_offset(d.getVar('NOR_BOOTCFG_START'))}"
FIP_A_PART_OFFSET = "${@convert_offset(d.getVar('NOR_FIP_A_START'))}"
FIP_B_PART_OFFSET = "${@convert_offset(d.getVar('NOR_FIP_B_START'))}"
KERNEL_A_PART_OFFSET = "${@convert_offset(d.getVar('NOR_KERNEL_A_START'))}"
KERNEL_B_PART_OFFSET = "${@convert_offset(d.getVar('NOR_KERNEL_B_START'))}"

#128MB to meet the nor flash spec.
IMAGE_TOTAL_SIZE="134217728"

python do_prepare_recipe_sysroot:prepend() {
    sizes_input  = int(d.getVar('NOR_BOOTCTRL_SIZE'))
    sizes_input += int(d.getVar('NOR_BOOTCFG_SIZE'))
    sizes_input += int(d.getVar('NOR_BOOT_SIZE'))
    sizes_input += int(d.getVar('NOR_BOOT_SIZE'))
    sizes_input += int(d.getVar('NOR_FIP_SIZE'))
    sizes_input += int(d.getVar('NOR_FIP_SIZE'))
    sizes_input += int(d.getVar('NOR_KERNEL_SIZE'))
    sizes_input += int(d.getVar('NOR_KERNEL_SIZE'))
    size_nor_flash = int(d.getVar('IMAGE_TOTAL_SIZE'))

    if sizes_input > size_nor_flash:
        bb.fatal("Error: the sum of input partition sizes is %d bytes, exceeding the nor flash capacity %d bytes!" % (sizes_input, size_nor_flash))
}

do_image_complete:prepend() {
    bb.build.exec_func('custom_nor_flash_image', d)
}

custom_nor_flash_image() {
    cp ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.wic ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.wic.tmp

    #MBR(512 bytes) is removed, by keeping byte 513th till the end
    tail -c +513 ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.wic.tmp > ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.dat

    gzip -kf ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.dat
}
