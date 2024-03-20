SUMMARY = "ADRV906x image"

IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_INSTALL:append = " \
    packagegroup-adrv906x-essential \
    "

IMAGE_ROOTFS_EXTRA_SPACE = "0"

# needs to be in sync with the size in adrv906x_mkext4fs()
IMAGE_ROOTFS_SIZE = "245760"

IMAGE_LINGUAS = " "

inherit core-image
inherit adi-rootfs-postcommands
inherit extrausers

# Enable access controls for ADRV906X reference design
require access-controls.inc

EXTRA_IMAGE_FEATURES:append = " data-partition"
EXTRA_IMAGE_FEATURES:append = "${@bb.utils.contains('ADI_CC_DM_VERITY_ENABLED', '1', ' read-only-rootfs', ' ', d)}"
IMAGE_INSTALL:append = " packagegroup-adrv906x-essential"
IMAGE_INSTALL:append = " \
    gptfdisk \
    iproute2 \
    libgpiod \
    libgpiod-tools \
    optee-apps \
    optee-apps-userspace \
    adrv906xinit \
    socat \
    watchdog \
    mtd-utils \
    logrotate \
    daemontools \
    perf \
    procps \
    ethtool \
    "

#TODO - add more packages, features to debug image when we support 4G  SD card and emmc
#NOW  - rootfs is limited to 256MB(support for larger in adi-console-debug image)
#wishlist: dbg-pkgs, packagegroup-core-tools-profile  packagegroup-core-buildessential"
PACKAGE_GROUPS_ADRV906X_DEBUG = " \
    packagegroup-adrv906x-debug \
    tcpreplay \
    "
IMAGE_INSTALL:append = "${@d.getVar('PACKAGE_GROUPS_ADRV906X_DEBUG') if  d.getVar('ADI_CC_DM_VERITY_ENABLED')=='0' else ''}"

IMAGE_DATA_PART_FILES = ""
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
