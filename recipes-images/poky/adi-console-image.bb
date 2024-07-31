SUMMARY = "Boot Image for ADI O-RAN platforms, suitable for production use."
LICENSE = "MIT"

ADRV906x_IMG = "recipes-images/adrv906x/adrv906x-base-image.bb"
FPGA_IMG     = "recipes-images/poky/adi-fpga-based-image.bb"

require ${@bb.utils.contains('ADI_SOC', 'adrv906x',  '${ADRV906x_IMG}', '', d)}

require ${@bb.utils.contains('MACHINE', 'adrv904x-rd-ru', '${FPGA_IMG}', '', d)}

DEPEND:append = " ${@bb.utils.contains('ADI_SOC', 'adrv906x',  'adrv906x-base-image', '', d)}"

python check_debug_img_enabled () {
    pn_val = d.getVar('PN')
    check_val = '1'
    set_val = '0'

    if 'debug' in pn_val:
        check_val = '0'
        set_val = '1'

    debug_enabled = d.getVar('ADI_CC_BOOT_DEBUG')
    if debug_enabled:
        if debug_enabled == check_val:
            bb.fatal("Error: ADI_CC_BOOT_DEBUG should be defined to \"%s\" in local.conf to build %s!" % (set_val,pn_val))
    else:
        bb.fatal("Error: ADI_CC_BOOT_DEBUG should be defined to \"%s\" in local.conf to build %s!" % (set_val,pn_val))
}

do_prepare_recipe_sysroot:prepend() {
    if d.getVar('ADI_SOC') == 'adrv906x':
        bb.build.exec_func('check_debug_img_enabled', d)
}
