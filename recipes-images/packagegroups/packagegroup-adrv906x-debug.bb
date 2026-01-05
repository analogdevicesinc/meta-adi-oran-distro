DESCRIPTION = "List of packages that are commonly needed for development purposes"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

PACKAGES = "${PN}"

RDEPENDS:${PN} = " \
    devmem2 \
    strace \
    valgrind \
    valgrind-callgrind \
    valgrind-cachegrind \
    valgrind-massif \
    iftop \
    sysstat \
    tcpdump \
    tcpreplay \
    libcap \
    libcap-bin \
    sudo \
    netsniff-ng \
    wget \
    rsync \
    kernel-dev \
    kernel-devsrc \
    cmake \
    spidev-test \
    ldd \
    e2fsprogs \
    iperf2 \
    iperf3 \
    i2c-tools \
    net-tools \
    adrv906x-debug-files \
    testptp \ 
    stress-ng \
    sysbench \
    iperf2 \
    uiomem \
    libyang-bin \
    "
