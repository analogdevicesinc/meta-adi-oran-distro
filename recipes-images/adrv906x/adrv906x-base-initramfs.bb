# Simple initramfs image. Mostly used for live images.
DESCRIPTION = "Small image capable of booting a device. The kernel includes \
the Minimal RAM-based Initial Root Filesystem (initramfs), which finds the \
first 'init' program more efficiently."

INITRAMFS_SCRIPTS ?= "\
                      initramfs-framework-base \
                     "

PACKAGE_INSTALL = "${INITRAMFS_SCRIPTS} ${VIRTUAL-RUNTIME_base-utils} udev base-passwd ${ROOTFS_BOOTSTRAP_INSTALL}"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""

IMAGE_NAME_SUFFIX ?= ""
IMAGE_LINGUAS = ""

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit core-image
inherit extrausers

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# Use the same restriction as initramfs-module-install
#COMPATIBLE_HOST = '(x86_64.*|i.86.*|arm.*|aarch64.*)-(linux.*|freebsd.*)'


PACKAGE_INSTALL:append = " initramfs-module-debug"
PACKAGE_INSTALL:append = " initramfs-module-init"
PACKAGE_INSTALL:append = " gptfdisk"
PACKAGE_INSTALL:append = " cryptsetup"
PACKAGE_INSTALL:append = " coreutils"
PACKAGE_INSTALL:append = " ppp"
PACKAGE_INSTALL:append = " jitterentropy"
PACKAGE_INSTALL:append = " dropbear"
PACKAGE_INSTALL:append = " rootfs-cfg"

IMAGE_FEATURES:append = " allow-empty-password empty-root-password allow-root-login"

#take out default root fs mount
BAD_RECOMMENDATIONS += "initramfs-module-rootfs "

# For use on secondary tile:
# 1) Disable root login
# 2) Add non-privileged, passwordless 'adi' account.
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
