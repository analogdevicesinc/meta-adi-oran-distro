SUMMARY = "Boot Image for ADI O-RAN platforms, suitable for production use."
LICENSE = "MIT"

FPGA_IMG     = "recipes-images/poky/adi-fpga-based-image.bb"

require ${@bb.utils.contains('MACHINE', 'adrv904x-rd-ru', '${FPGA_IMG}', '', d)}
