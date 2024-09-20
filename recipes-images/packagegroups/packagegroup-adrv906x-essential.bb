DESCRIPTION = "Packages required for fundamental operation"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

PACKAGES = "${PN}"

RDEPENDS:${PN}:append:denali-4 = " reduce-fan-speed"
RDEPENDS:${PN}:append:denali-8 = "reduce-fan-speed"
RDEPENDS:${PN}:append:titan-4 = " reduce-fan-speed"
RDEPENDS:${PN}:append:titan-8 = " reduce-fan-speed"

RDEPENDS:${PN} = " \
	kmod \
	ppp \
	jitterentropy \
	iproute2 \
	openssh \
	adrv906x-files \
	data-partition \
	os-release \
	swupdate \
	swupdate-lua \
	swupdate-client \
	swupdate-progress \
	"
