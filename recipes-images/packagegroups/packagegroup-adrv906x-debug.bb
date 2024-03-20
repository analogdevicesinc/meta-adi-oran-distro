DESCRIPTION = "List of packages that are commonly needed for development purposes"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

PACKAGES = "${PN}"

RDEPENDS:${PN} = " \
    devmem2 \
    gdbserver \
    gdb \
    strace \
    valgrind \
    iperf2 \
    iperf3 \
    iftop \
    sysstat \
    i2c-tools \
    libiio \
    linuxptp \
    tcpdump \
	"
