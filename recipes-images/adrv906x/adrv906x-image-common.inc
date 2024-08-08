SUMMARY = "ADRV906x image"

IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_INSTALL:append = " \
    packagegroup-adrv906x-essential \
    "

IMAGE_ROOTFS_EXTRA_SPACE = "0"

# needs to be in sync with the size in adrv906x_mkext4fs()
IMAGE_ROOTFS_SIZE = "1908736"

IMAGE_LINGUAS = " "

inherit core-image
inherit adi-rootfs-postcommands
inherit extrausers

# Enable access controls for ADRV906X reference design
require access-controls.inc

EXTRA_IMAGE_FEATURES:append = " read-only-rootfs data-partition"
IMAGE_INSTALL:append = " packagegroup-adrv906x-essential"
IMAGE_INSTALL:append = " \
    gptfdisk \
    iproute2 \
    libgpiod \
    libgpiod-tools \
    optee-apps \
    optee-apps-userspace \
    rng-tools \
    adrv906xinit \
    socat \
    watchdog \
    mtd-utils \
    logrotate \
    daemontools \
    procps \
    ethtool \
    linux-ready-led \
    rootfs-anti-rollback \
    nftables \
    linuxptp \
    openssh-sftp-server \
    tzdata \
    "

IMAGE_INSTALL:append:titan = " pushbutton-mon"
IMAGE_INSTALL:append:titan-4 = " adrv906x-qsfp-sfp-control"
IMAGE_INSTALL:append:denali = " \
    pushbutton-mon \
    adrv906x-qsfp-sfp-control \
    "

#TODO - add more packages, features to debug image when we support 4G  SD card and emmc
#NOW  - rootfs is limited to 256MB(support for larger in adi-console-debug image)
#wishlist: dbg-pkgs, packagegroup-core-tools-profile  packagegroup-core-buildessential"
PACKAGE_GROUPS_ADRV906X_DEBUG = " \
    packagegroup-adrv906x-debug \
    packagegroup-core-buildessential \
    packagegroup-core-tools-debug \
    packagegroup-core-tools-profile \
    "
IMAGE_INSTALL:append = "${@d.getVar('PACKAGE_GROUPS_ADRV906X_DEBUG') if  d.getVar('ADI_CC_BOOT_DEBUG')=='1' else ''}"
EXTRA_IMAGE_FEATURES:remove = "${@bb.utils.contains('ADI_CC_BOOT_DEBUG', '0', 'debug-tweaks', '', d)}"

IMAGE_DATA_PART_FILES = " \
    /etc/adjtime \
    "
IMAGE_DATA_PART_FILES_WITH_DFLTS = " \
    /etc/dropbear/keys \
    /etc/network/interfaces \
    /var/lib \
    /etc/syslog.conf \
    /etc/syslog-startup.conf \
    /etc/logrotate.conf \
    /etc/logrotate-dmesg.conf \
    /etc/logrotate.d \
    "

# Example to add service:
# IMAGE_INSTALL:append = " example_service"
# IMAGE_DATA_PART_FILES_WITH_DFLTS:append = " /usr/local/bin/service/example_service/supervise"

# If ADI_CC_USER_DB_ON_DATA_PART is set, move all user/group database related items to the data partition (/data/active)
IMAGE_DATA_PART_FILES_WITH_DFLTS:append = "${@bb.utils.contains('ADI_CC_USER_DB_ON_DATA_PART','1',' /etc/passwd /etc/group /etc/shadow /etc/gshadow ', ' ', d)}"
