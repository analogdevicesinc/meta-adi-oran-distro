DESCRIPTION = "Packages required for fundamental operation"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

PACKAGES = "${PN}"

RDEPENDS:${PN} = " \
	e2fsprogs \
	iperf2 \
	iperf3 \
	linuxptp \
	openssh-sftp-server \
	pciutils \
	networkmanager \
	net-tools \
	ethtool \
	sudo \
	vim \
	rsync \
	wget \
	i2c-tools \
	kmod \
	netplan \
	dos2unix \
	wpa-supplicant \
	iproute2 \
	adi-files-sysv \
	os-release \
	"
RDEPENDS:${PN}:append:enable_systemd = "adi-files"
RDEPENDS:${PN}:remove:enable_systemd = "adi-files-sysv"

DEPENDS:append:adrv904x-rd-ru        = " adi-fpga-image"
DEPENDS:append:adrv904x-rd-ru        = "${@bb.utils.contains('ADI_CC_RSU', '1', ' adi-rsu-client', '', d)}"
RDEPENDS:${PN}:append:adrv904x-rd-ru = "${@bb.utils.contains('ADI_CC_RSU', '1', ' intel-rsu', '', d)}"

