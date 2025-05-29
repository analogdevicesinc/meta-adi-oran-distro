# Simple initramfs image. Mostly used for live images.
DESCRIPTION = "Small image capable of booting a device. The kernel includes \
the Minimal RAM-based Initial Root Filesystem (initramfs), which finds the \
first 'init' program more efficiently."

INITRAMFS_SCRIPTS ?= "\
                      initramfs-framework-base \
                     "

PACKAGE_INSTALL = "${INITRAMFS_SCRIPTS} ${VIRTUAL-RUNTIME_base-utils}"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""
# Do not pollute the initrd image with rootfs extra features (as debug-tweaks)
EXTRA_IMAGE_FEATURES = ""

IMAGE_LINGUAS = ""

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit core-image
inherit extrausers

IMAGE_NAME_SUFFIX = ""
IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# Add our own init file for the initramfs
PACKAGE_INSTALL:append = " initramfs-module-init"
# Add gdisk utility, used by our init
PACKAGE_INSTALL:append = " gptfdisk"
# Add our rootfs configuration file, sourced by our init
PACKAGE_INSTALL:append = " rootfs-cfg"

# Required for secure boot (dm-verity)
ADI_INITRAMFS_DM_VERITY_PACKAGES = "cryptsetup"
PACKAGE_INSTALL:append = " ${@bb.utils.contains('DM_VERITY_ENABLED','1','${ADI_INITRAMFS_DM_VERITY_PACKAGES}','', d)}"

# Image features for debug
ADI_INITRAMFS_DEBUG_FEATURES = "allow-empty-password \
                                empty-root-password \
                                allow-root-login"
IMAGE_FEATURES:append = " ${@bb.utils.contains('ADI_CC_BOOT_DEBUG','1','${ADI_INITRAMFS_DEBUG_FEATURES}','', d)}"

# Extra image features for debug
ADI_INITRAMFS_DEBUG_EXTRA_FEATURES = "debug-tweaks"
EXTRA_IMAGE_FEATURES:append = " ${@bb.utils.contains('ADI_CC_BOOT_DEBUG','1','${ADI_INITRAMFS_DEBUG_EXTRA_FEATURES}','', d)}"

# Packages for debug
ADI_INITRAMFS_DEBUG_PACKAGES = "nfs-rootfs"
PACKAGE_INSTALL:append = " ${@bb.utils.contains('ADI_CC_BOOT_DEBUG','1','${ADI_INITRAMFS_DEBUG_PACKAGES}','', d)}"

# Setup SSH server on the secondary
PACKAGE_INSTALL:append = " coreutils"
PACKAGE_INSTALL:append = " ppp"
PACKAGE_INSTALL:append = " jitterentropy"
PACKAGE_INSTALL:append = " dropbear"
PACKAGE_INSTALL:append = " e2fsprogs"

# For use on secondary tile:
# 1) Disable root login
# 2) Add non-privileged, passwordless 'adi' account.
IMAGE_FEATURES:append = " allow-empty-password"
EXTRA_USERS_PARAMS = "\
    usermod -L -e 1 -s /sbin/nologin root; \
    useradd -p '' adi; \
    "

python do_rootfs:append() {
    import os
    import glob
    path = os.path.join(d.getVar("IMAGE_ROOTFS"), 'boot', 'fitImage')
    for file in glob.glob(f'{path}*'):
        os.remove(file)
    path = os.path.join(d.getVar("IMAGE_ROOTFS"), 'boot', 'Image')
    for file in glob.glob(f'{path}*'):
        os.remove(file)
}
