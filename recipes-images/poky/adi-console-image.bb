SUMMARY = "Boot Image for ADI O-RAN platforms, suitable for production use."
LICENSE = "MIT"

COMPATIBLE_MACHINE:append ?= "titan-*|"

ADRV906x_IMG = "recipes-images/adrv906x/adrv906x-base-image.bb"
FPGA_IMG     = "recipes-images/poky/adi-fpga-based-image.bb"

require ${@bb.utils.contains('MACHINE', 'titan-4',   '${ADRV906x_IMG}', '', d)}
require ${@bb.utils.contains('MACHINE', 'titan-8',   '${ADRV906x_IMG}', '', d)}

require ${@bb.utils.contains('MACHINE', 'adrv904x-rd-ru', '${FPGA_IMG}', '', d)}

DEPEND:append:titan-4 = " adrv906x-base-image"
DEPEND:append:titan-8 = " adrv906x-base-image"

python check_dm_verity () {
    pn_val = d.getVar('PN')
    check_val = '0'
    set_val = '1'

    if 'debug' in pn_val:
        check_val = '1'
        set_val = '0'

    dm_verity_enabled = d.getVar('ADI_CC_DM_VERITY_ENABLED')
    if dm_verity_enabled:
        if dm_verity_enabled == check_val:
            bb.fatal("Error: ADI_CC_DM_VERITY_ENABLED should be defined to \"%s\" in local.conf to build %s!" % (set_val,pn_val))
    else:
        bb.fatal("Error: ADI_CC_DM_VERITY_ENABLED should be defined to \"%s\" in local.conf to build %s!" % (set_val,pn_val))
}

do_prepare_recipe_sysroot:prepend:titan-4() {
    bb.build.exec_func('check_dm_verity', d)
}
do_prepare_recipe_sysroot:prepend:titan-8() {
    bb.build.exec_func('check_dm_verity', d)
}