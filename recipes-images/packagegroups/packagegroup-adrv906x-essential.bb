DESCRIPTION = "Packages required for fundamental operation"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

PACKAGES = "${PN}"

RDEPENDS:${PN} = " \
	kmod \
	ppp \
	jitterentropy \
	dropbear \
	adrv906x-files \
	data-partition \
	"

