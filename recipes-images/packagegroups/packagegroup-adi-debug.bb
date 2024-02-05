DESCRIPTION = "List of packages that are commonly needed for development purposes"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

PACKAGES = "${PN}"

RDEPENDS:${PN} = " \
	kernel-dev \
	kernel-devsrc \
	devmem2 \
	git \
	cmake \
	tzdata \
	gnupg \
	ca-certificates \
	zeromq \
	iputils-ping \
	tcpdump \
	tcpreplay \
	strace \
	python3 \
	python3-pip \
	python3-numpy \
	dosfstools \
	gdbserver \
	gcc \
	g++ \
	procps \
	spidev-test \
	"
